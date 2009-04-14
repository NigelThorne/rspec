require File.dirname(__FILE__) + '/../../spec_helper'

module Spec
  module Mocks
    describe Mock do
      before(:each) do
        @mock = mock("test mock")
      end
      
      after(:each) do
      end
      
      it "should match the correct expectation when one is already satisfied" do
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
end
