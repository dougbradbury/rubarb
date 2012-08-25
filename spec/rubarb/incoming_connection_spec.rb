require 'spec_helper'

require "rubarb/incoming_connection"
require "rubarb/remote_call"
require "rubarb/default"

describe Rubarb::IncomingConnection do
  include Rubarb::RemoteCall
  include Rubarb::IncomingConnection
  attr_reader :api

  class TestApi
    attr_accessor :dodo
    def amethod(responder, dodo)
      @dodo = dodo
    end
    def ==(rhs)
    end
  end

  before(:each) do
    @api = TestApi.new
    @insecure_methods = Rubarb::Default::INSECURE_METHODS
  end

  it "should receive message" do
    receive_message(marshal_call("00000001", :amethod, "goo"))
    @api.dodo.should == "goo"
  end

  it "should receive reply with exception when a non-existent method is called" do
    should_receive(:reply).with do |id, exception|
      id.should == "0"
      exception.message.include?("undefined method").should == true
    end
    receive_message(marshal_call("00000001", :not_a_method, "foo"))
    @api.should_not_receive(:send)
  end

  def blocks_method_in_receive_message(method)
    @method = method
    should_receive(:reply).with do |id, exception|
      id.should == "0"
      exception.message.should == "Remote client attempts to call method #{@method}, but was denied."
    end
    receive_message(marshal_call("00000001", method, "foo"))
    @api.should_not_receive(:send)
  end

  it "blocks :== in receive_message" do
    blocks_method_in_receive_message(:==)
  end

  it "blocks any insecure method in receive_message" do
    Rubarb::Default::INSECURE_METHODS.each do |method|
      blocks_method_in_receive_message(method)
    end
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

  it "should handle empty message" do
    self.should_not_receive(:send_message)
    receive_message(marshal_call(""))
  end

end
