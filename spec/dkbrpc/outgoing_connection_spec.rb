require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "dkbrpc/outgoing_connection"
require "dkbrpc/remote_call"

describe Dkbrpc::OutgoingConnection do
  include Dkbrpc::RemoteCall
  include Dkbrpc::OutgoingConnection
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

  it "sets callback" do
    block = Proc.new { puts "Hello" }
    self.should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    @callback.should == block
  end

  it "executes callback block when receive_message is called" do
    block = Proc.new do |m|
      @method = m
    end
    self.should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)

    stub!(:unmarshal_call).and_return(:amethod)
    receive_message("message")
    @method.should == :amethod
  end

  it "does not execute callback block when receive_message is called with an exception" do
    block = Proc.new { puts "Hello" }
    self.should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    @callback.should_not_receive(:call)
    receive_message(marshal_call(Exception.new))
  end

  it "saves error message when receive_message is called with an exception" do
    block = Proc.new { puts "Hello" }
    self.should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    @callback.stub!(:call)

    error = nil
    @errback = Proc.new { |e| error = e }

    exception = Exception.new("Hello")
    receive_message(marshal_call(exception))

    error.class.should == Exception
    error.message.should == (exception.message)
  end

#  def receive_message(message)
#    @callback.call(*unmarshal_call(message)) if @callback
#  end


end
