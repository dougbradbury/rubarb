require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubarb/server'
require 'rubarb/connection'

describe "Connection Failures" do

  before(:each) do
    @reactor = start_reactor
  end

  after(:each) do
    stop_reactor(@reactor)
  end
  
  it "should fail to connect" do
    @connection = Rubarb::Connection.new("127.0.0.1", 9441, mock("client api"))

    @errback_called = false
    @connection.errback do |error|
      @errback_called = true
      error.class.should == Rubarb::ConnectionError
      error.message.should == "Connection Failure"
    end

    @callback_called = false
    @connection.start do |remote_end|
      @callback_called = true
    end

    wait_for {@errback_called}

    @errback_called.should == true
    @callback_called.should == false
  end

  it "should fail after it has connected" do
    @server = Rubarb::Server.new("127.0.0.1", 9441, mock("server"))
    @connection = Rubarb::Connection.new("127.0.0.1", 9441, mock("client"))
    @connection2 = Rubarb::Connection.new("127.0.0.1", 9441, mock("client"))

    @server.start

    @errback_called = false
    @connection.errback do |error|
      @errback_called = true
      error.class.should == Rubarb::ConnectionError
      error.message.should == "Connection Failure"
    end

    @errback2_called = false
    @connection2.errback do |error|
      @errback2_called = true
      error.class.should == Rubarb::ConnectionError
      error.message.should == "Connection Failure"
    end

    @connection.start do
      @server.stop
    end

    @connection2.start

    wait_for{@errback_called}
    @errback_called.should be_true

    wait_for{@errback2_called}
    @errback2_called.should be_true
  end

end
