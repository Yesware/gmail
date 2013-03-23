shared_examples_for "a mailbox switcher" do
  it "should properly switch to given mailbox" do
    mock_client do |client|
      client.labels.create("TEST")
      mailbox = client.mailbox("TEST")
      mailbox.should be_kind_of(Gmail::Mailbox)
      mailbox.name.should == "TEST"
      client.labels.delete("TEST")
    end
  end

  it "should properly switch to given mailbox using block style" do
    mock_client do |client|
      client.labels.create("TEST")
      client.mailbox("TEST") do |mailbox|
        mailbox.should be_kind_of(Gmail::Mailbox)
        mailbox.name.should == "TEST"
      end
      client.labels.delete("TEST")
    end
  end
end