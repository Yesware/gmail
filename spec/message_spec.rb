require 'spec_helper'

describe "A Gmail message" do
  subject { Gmail::Message }

  context "on initialize" do
    it "should set uid and mailbox" do
      mock_mailbox do |mailbox|
        message = subject.new(mailbox, -1)
        message.instance_variable_get("@mailbox").should == mailbox
        message.uid.should == -1
        message.instance_variable_get("@gmail").should == mailbox.instance_variable_get("@gmail")
      end
    end
  end
  
  context "instance" do
    def with_first_message(&block)
      mock_mailbox do |mailbox|
        message = mailbox.emails.first
        yield message
      end
    end

    it "should be able to mark itself as read" do
      with_first_message { |message| message.read! }
    end
    
    it "should be able to mark itself as unread" do
      with_first_message { |message| message.unread! }
    end
    
    it "should be able to star itself" do
      with_first_message { |message| message.star! }
    end
    
    it "should be able to unstar itself" do
      with_first_message { |message| message.unstar! }
    end
    
    it "should be able to archive itself" do
      pending
    end
    
    it "should be able to delete itself" do
      pending
    end
    
    it "should be able to move itself to spam" do
      pending
    end
    
    it "should be able to set given label" do
      mock_mailbox do |mailbox|
        gmail = mailbox.instance_variable_get('@gmail')
        gmail.labels.create('TEST')
        message = mailbox.emails.first
        message.label('TEST')
        gmail.labels.delete('TEST')
      end
    end
    
    it "should be able to mark itself with given flag" do
      pending
    end
    
    it "should be able to move itself to given box" do
      pending
    end

    context "with a read-only mailbox" do
      def expect_read_only(&block)
        expect do
          yield
        end.to raise_error(Net::IMAP::NoResponseError)
      end

      def with_first_message(&block)
        mock_mailbox('INBOX', true) do |mailbox|
          message = mailbox.emails.first
          yield message
        end
      end

      it "should be unable to mark itself as read" do
        expect_read_only { with_first_message { |message| message.read! } }
      end

      it "should be unable to mark itself as unread" do
        expect_read_only { with_first_message { |message| message.unread! } }
      end

      it "should be unable to star itself" do
        expect_read_only { with_first_message { |message| message.star! } }
      end

      it "should be unable to unstar" do
        expect_read_only { with_first_message { |message| message.unstar! } }
      end

      it "should be able to set given label" do
        # This is treated as copy to a new folder in IMAP
        # and allowed even if the mailbox is read-only
        mock_mailbox('INBOX', true) do |mailbox|
          gmail = mailbox.instance_variable_get('@gmail')
          gmail.labels.create('TEST')
          message = mailbox.emails.first
          message.label('TEST')
          gmail.labels.delete('TEST')
        end
      end
    end
  end 
end
