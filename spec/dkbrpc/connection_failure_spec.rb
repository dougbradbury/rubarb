require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'dkbrpc/server'
require 'dkbrpc/connection'

describe "Connection Failures" do

  before(:each) do
    @reactor = start_reactor
  end

  after(:each) do
    stop_reactor(@reactor)
  end
  
  it "should fail to connect" do
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client api"))

    @errback_called = false
    @connection.errback do |error|
      @errback_called = true
      error.should == "Connection Failure"
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
    @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
    @connection2 = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))

    @server.start

    @errback_called = false
    @connection.errback do |error|
      @errback_called = true
      error.should == "Connection Failure"
    end


    @errback2_called = false
    @connection2.errback do |error|
      @errback2_called = true
      error.should == "Connection Failure"
    end

    @connected = false
    @connection.start do |server|
      @connected = true
    end

    @connection2.start

    wait_for{@connected}

    puts "stopping connection"
    @server.stop

    wait_for{@errback_called}
    @errback_called.should == true
    wait_for{@errback2_called}
    @errback2_called.should == true

  end
end