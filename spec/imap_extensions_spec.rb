require 'spec_helper'
require 'gmail/client/imap_extensions'

describe Net::IMAP::ResponseParser do

  # http://bugs.ruby-lang.org/issues/5163
  it "should handle extra spaces before the )" do
    parser = Net::IMAP::ResponseParser.new
    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 1 FETCH (UID 92285)
EOF
    response.data.attr["UID"].should == 92285

    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 1 FETCH (UID 92285 )
EOF
    response.data.attr["UID"].should == 92285

    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 1 FETCH (UID 92285  )
EOF
    response.data.attr["UID"].should == 92285
  end

  it "should handle Gmail labels with parentheses" do
    parser = Net::IMAP::ResponseParser.new
    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 5695 FETCH (X-GM-THRID 1404218392132219629 X-GM-MSGID 1404218392132219629 X-GM-LABELS ("\\Inbox" "\\Important" "Post (Truro)") UID 16437 BODYSTRUCTURE ("TEXT" "HTML" ("CHARSET" "us-ascii") NIL NIL "QUOTED-PRINTABLE" 661 9 NIL NIL NIL))
EOF
    response.data.attr["BODYSTRUCTURE"].param["CHARSET"].should == "us-ascii"
    response.data.attr["X-GM-LABELS"].should == [:Inbox, :Important, "Post (Truro)"]

    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 2446 FETCH (X-GM-THRID 1402858025049529478 X-GM-MSGID 1402858025049529478 X-GM-LABELS ("\\Important" "KountryKash (old)") UID 790801 BODYSTRUCTURE ("TEXT" "PLAIN" ("CHARSET" "utf-8") NIL NIL "8BIT" 962 38 NIL NIL NIL))
EOF
    response.data.attr["X-GM-LABELS"].should == [:Important, "KountryKash (old)"]
  end

  it "should handle no labels" do
    parser = Net::IMAP::ResponseParser.new
    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 2446 FETCH (X-GM-THRID 1402858025049529478 X-GM-MSGID 1402858025049529478 X-GM-LABELS () UID 790801 BODYSTRUCTURE ("TEXT" "PLAIN" ("CHARSET" "utf-8") NIL NIL "8BIT" 962 38 NIL NIL NIL))
EOF
    response.data.attr["X-GM-LABELS"].should == []
  end

  it "should handle unquoted strings with non-alphanumeric characters" do
    parser = Net::IMAP::ResponseParser.new
    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 2446 FETCH (X-GM-THRID 1402858025049529478 X-GM-MSGID 1402858025049529478 X-GM-LABELS (info@capital-group.it "\\Inbox") UID 790801 BODYSTRUCTURE ("TEXT" "PLAIN" ("CHARSET" "utf-8") NIL NIL "8BIT" 962 38 NIL NIL NIL))
EOF
    response.data.attr["X-GM-LABELS"].should == ["info@capital-group.it", :Inbox]

    response = parser.parse(<<EOF.gsub(/\n/, "\r\n").taint)
* 2446 FETCH (X-GM-THRID 1402858025049529478 X-GM-MSGID 1402858025049529478 X-GM-LABELS (Business/Marketing/Newsletter/Emailers/Advert) UID 790801 BODYSTRUCTURE ("TEXT" "PLAIN" ("CHARSET" "utf-8") NIL NIL "8BIT" 962 38 NIL NIL NIL))
EOF
    response.data.attr["X-GM-LABELS"].should == ["Business/Marketing/Newsletter/Emailers/Advert"]
  end

end