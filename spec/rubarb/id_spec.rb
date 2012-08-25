require 'spec_helper'
require 'rubarb/id'

include Rubarb

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

  it "resets counter to one if id is 99999999" do
    @id.instance_eval{ @id = 99999999 }
    @id.next
    @id.next.should == "00000001"
  end
end
