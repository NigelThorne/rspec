require File.dirname(__FILE__) + '/../../spec_helper'

module Bug793
  describe "Bug report 793" do
    it "should match the unsatisfied expectations in preference to satisfied ones" do
      @mock = mock("test mock")
      @mock.should_receive(:a).ordered
      @mock.should_receive(:b).ordered
      @mock.should_receive(:a).ordered
      
      @mock.a
      @mock.b
      @mock.a
      @mock.rspec_verify
    end
  end
end
