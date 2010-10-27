require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'dkbrpc/id'

include Dkbrpc

describe Id do

  before(:each) do
    @id = Id.new
  end

  it "starts generator at 00000001" do
    @id.next.should == "00000001"
  end

  it "increments counter by 1 when next is called" do
    @id.next
    @id.next.should == "00000002"
  end

end
