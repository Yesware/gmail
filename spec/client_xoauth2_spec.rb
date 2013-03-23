require 'spec_helper'

describe "Gmail client (XOAuth2)" do
  subject { Gmail::Client::XOAuth2 }

  context "on initialize" do
    it "should set username, oauth2_token and options" do
      client = subject.new("test@gmail.com", {
        :oauth2_token => "token",
        :foo          => :bar
      })
      client.username.should == "test@gmail.com"
      client.oauth2_token.should == "token"
      client.options[:foo].should == :bar
    end

    it "should convert simple name to gmail email" do
      client = subject.new("test", {:oauth2_token => "token"})
      client.username.should == "test@gmail.com"
    end
  end

  context "instance" do
    def mock_client(&block) 
      client = Gmail::Client::XOAuth2.new(*TEST_ACCOUNT["xoauth2"])
      if block_given?
        client.connect
        yield client
        client.logout
      end
      client
    end

    it "should connect to GMail IMAP service" do 
      lambda { 
        client = mock_client
        client.connect!.should be_true
      }.should_not raise_error(Gmail::Client::ConnectionError)
    end

    it "should properly login to valid GMail account" do
      client = mock_client
      client.connect.should_not be_nil
      client.login.should be_true
      client.should be_logged_in
      client.logout
    end

    it "should raise error when given GMail account is invalid and errors enabled" do
      lambda {
        client = Gmail::Client::XOAuth2.new("foo", {:oauth2_token=>"bar"})
        client.connect.should be_true
        client.login!.should_not be_true
      }.should raise_error(Gmail::Client::AuthorizationError)
    end

    it "shouldn't login when given GMail account is invalid" do
      lambda {
        client = Gmail::Client::XOAuth2.new("foo", {:oauth2_token=>"bar"})
        client.connect.should be_true
        client.login.should_not be_true
      }.should_not raise_error(Gmail::Client::AuthorizationError)
    end

    it "should properly logout from GMail" do
      client = mock_client
      client.connect
      client.login.should be_true
      client.logout.should be_true
      client.should_not be_logged_in
    end

    it "#connection should automatically log in to GMail account when it's called" do
      mock_client do |client|
        client.expects(:login).once.returns(false)
        client.connection.should_not be_nil
      end
    end

    it "should properly compose message" do
      mail = mock_client.compose do
        from "test@gmail.com"
        to "friend@gmail.com"
        subject "Hello world!"
      end
      mail.from.should == ["test@gmail.com"]
      mail.to.should == ["friend@gmail.com"]
      mail.subject.should == "Hello world!"
    end

    it "#compose should automatically add `from` header when it is not specified" do
      mail = mock_client.compose
      mail.from.should == [TEST_ACCOUNT["xoauth2"][0]]
      mail = mock_client.compose(Mail.new)
      mail.from.should == [TEST_ACCOUNT["xoauth2"][0]]
      mail = mock_client.compose {}
      mail.from.should == [TEST_ACCOUNT["xoauth2"][0]]
    end

    it "should deliver inline composed email" do
      mock_client do |client|
        client.deliver do
          to TEST_ACCOUNT["xoauth2"][0]
          subject "Hello world!"
          body "Yeah, hello there!"
        end.should be_true
      end
    end

    it "should not raise error when mail can't be delivered and errors are disabled" do
      lambda {
        client = mock_client
        client.deliver(Mail.new {}).should be_false
      }.should_not raise_error(Gmail::Client::DeliveryError)
    end

    it "should raise error when mail can't be delivered and errors are disabled" do
      lambda {
        client = mock_client
        client.deliver!(Mail.new {})
      }.should raise_error(Gmail::Client::DeliveryError)
    end

    it_behaves_like "a mailbox switcher"

    context "labels" do
      subject {
        client = Gmail::Client::XOAuth2.new(*TEST_ACCOUNT["xoauth2"])
        client.connect
        client.labels
      }

      it_behaves_like "a label manipulator"
    end
  end
end
