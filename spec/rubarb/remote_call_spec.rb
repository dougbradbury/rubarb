require 'spec_helper'

require 'rubarb/remote_call'
describe Rubarb::RemoteCall do
  include Rubarb::RemoteCall

  it "should marshal a call" do
    identity_test(:foo, "barr", "none")
  end

  it "should marshal with no args" do
    identity_test(:food)
  end

  it "should work with multiple return values" do
    serialized = marshal_call(:eat, "potatos", "carrots")
    recovered_method, arg1, arg2 = unmarshal_call(serialized)
    recovered_method.should == :eat
    arg1.should == "potatos"
    arg2.should == "carrots"
  end

  class Wine
    attr_accessor :age, :content
    def initialize(age, content)
      @age = age
      @content = content
    end

    def ==(other)
      return false unless self.age == other.age
      return false unless self.content == other.content
      return true
    end
  end

  it "should handle complexy objects" do
    identity_test(:make_grapes, Wine.new(15, 0.15), "grapes")
  end

  def identity_test(method, *args)
    serialized = marshal_call(method, *args)
    recovered_method, *recovered_args = unmarshal_call(serialized)
    recovered_method.should == method
    recovered_args.should == args
  end

end
