require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'dkbrpc/server'
require "dkbrpc/remote_call"

describe Dkbrpc::Listener do
  include Dkbrpc::RemoteCall

  before(:each) do
    self.extend(Dkbrpc::Listener)
    @sent_data = ""
    self.stub!(:send_data) do |data|
      @sent_data = data
    end
    post_init
  end

  it "should generate and send connection ID" do
    Dkbrpc::Id.stub(:next).and_return("00000001")
    receive_data("4")
    @sent_data.should == "00000001"
    Dkbrpc::RemoteClient.find("00000001").incomming.should_not be_nil
  end

  it "should receive another connection" do
    receive_data("5")
    receive_data("00000005")
    @sent_data.should == ""
    @id.should == "00000005"
    Dkbrpc::RemoteClient.find("00000005").outgoing.should_not be_nil
  end

#  class TestApi
#    attr_accessor :dodo
#    def amethod(responder, dodo)
#      @dodo = dodo
#    end
#  end
#
#  it "should receive message " do
#    @api = TestApi.new
#    receive_message(marshal_call(:amethod, "goo"))
#    @api.dodo.should == "goo"
#  end
end