require 'spec_helper'

describe "A Gmail mailbox" do
  subject { Gmail::Mailbox }

  context "on initialize" do
    it "should set client, name, and read_only status" do
      within_gmail do |gmail|
        mailbox = subject.new(gmail, "TEST", true)
        mailbox.instance_variable_get("@gmail").should == gmail
        mailbox.name.should == "TEST"
        mailbox.read_only.should be_true
      end
    end

    it 'defaults to the client setting for read only' do
      within_gmail do |gmail|
        gmail.options[:read_only] = true
        mailbox = subject.new(gmail)
        mailbox.read_only.should be_true
      end
    end

    it "should work in INBOX by default" do
      within_gmail do |gmail|
        mailbox = subject.new(gmail)
        mailbox.name.should == "INBOX"
      end
    end
  end

  context "instance" do

    describe '#count' do
      it "should be able to count all emails" do
        mock_mailbox do |mailbox|
          mailbox.count.should > 0
        end
      end
    end

    describe '#emails' do
      it "should be able to find messages" do
        mock_mailbox do |mailbox|
          message = mailbox.emails.first
          mailbox.emails(:all, :from => message.from.first.name) == message.from.first.name
        end
      end

      context "with a block" do
        it "performs operations on the found messages using the mailbox's read-only setting" do
          mock_mailbox do |mailbox|
            # Another test creates sends emails with this subject
            mailbox.emails(:subject => 'Hello world!') do |message|
              message.instance_variable_get("@mailbox").read_only.should be_false
            end
          end
        end

        context "for a read-only mailbox" do
          it "performs operations on the messages using the mailbox's read-only setting" do
            mock_mailbox('INBOX', true) do |mailbox|
              mailbox.emails(:subject => 'Hello world!') do |message|
                message.instance_variable_get("@mailbox").read_only.should be_true
              end
            end
          end
        end
      end

      it "should be able to do a full text search of message bodies" do
        pending "This can wait..."
        #mock_mailbox do |mailbox|
        #  message = mailbox.emails.first
        #  body = message.parts.blank? ? message.body.decoded : message.parts[0].body.decoded
        #  emails = mailbox.emails(:search => body.split(' ').first)
        #  emails.size.should > 0
        #end
      end
    end

  end
end
