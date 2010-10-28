require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "dkbrpc/incoming_connection"
require "dkbrpc/remote_call"

describe Dkbrpc::IncomingConnection do
  include Dkbrpc::RemoteCall
  include Dkbrpc::IncomingConnection
  attr_reader :api

  class TestApi
    attr_accessor :dodo
    def amethod(responder, dodo)
      @dodo = dodo
    end
  end

  before(:each) do
    @api = TestApi.new
  end

  it "should receive message " do
    receive_message(marshal_call("00000001", :amethod, "goo"))
    @api.dodo.should == "goo"
  end

  it "should receive reply with exception when a non-existent method is called" do
    should_receive(:reply).with do |id, exception|
      id.should == "0"
      exception.message.include?("undefined method").should == true
    end
    receive_message(marshal_call("00000001", :not_a_method, "foo"))
    @api.dodo.should_not == "foo"
  end

  it "receives message with id, method, and *args" do
    message = marshal_call("00000001", :amethod, "foo")
    receive_message(message)
    @api.dodo.should == "foo"
  end

  it "replies message with id and args" do
    message = marshal_call("00000001", :amethod, "foo")
    receive_message(message)
    self.should_receive(:send_message).with(marshal_call(["00000001", "result"]))
    reply("00000001", "result")
  end

  it "replies message with id 00000002 and args" do
    message = marshal_call("00000002", :amethod, "foo")
    receive_message(message)
    self.should_receive(:send_message).with(marshal_call(["00000002", "result"]))
    reply("00000002", "result")
  end
end
