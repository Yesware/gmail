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

  it "should allow nested mailbox access" do
    mock_client do |client|
      client.labels.create("TEST")
      client.labels.create("TEST2")

      # Add a mailbox to the stack
      client.send(:mailbox_stack) << 'TEST'
      client.mailboxes['TEST'] = Gmail::Mailbox.new(client, 'TEST', true)

      client.mailbox("TEST2") do |mailbox|
        mailbox.name.should == "TEST2"
      end

      client.labels.delete("TEST")
      client.labels.delete("TEST2")
    end
  end
end