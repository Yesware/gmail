shared_examples_for "a label manipulator" do
  before(:all) do
    subject.create("TEST")
  end
  after(:all) do
    subject.delete("TEST")
  end

  it "should get list of all available labels" do
    labels = subject
    labels.all.should include("TEST", "INBOX")
  end

  it "should be able to check if there is given label defined" do
    labels = subject
    labels.exists?("TEST").should be_true
    labels.exists?("FOOBAR").should be_false
  end

  it "should be able to create given label" do
    labels = subject
    labels.create("MYLABEL")
    labels.exists?("MYLABEL").should be_true
    labels.create("MYLABEL").should be_false
    labels.delete("MYLABEL")
  end

  it "should be able to remove existing label" do
    labels = subject
    labels.create("MYLABEL")
    labels.delete("MYLABEL").should be_true
    labels.exists?("MYLABEL").should be_false
    labels.delete("MYLABEL").should be_false
  end
end