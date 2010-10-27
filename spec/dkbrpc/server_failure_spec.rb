require 'dkbrpc/server'
require 'dkbrpc/connection'
require 'socket'

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Server Failures" do
  before(:each) do
    @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
    @connection1 = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
    @connection2 = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
  end

  def wait_for_connections(n, ttl, &block)
    if ttl <= 0
      fail("TTL expired")
    end

    if @cons != n
      EventMachine.add_periodic_timer(0.1) do
        wait_for_connections(n, ttl-1, &block)
      end
    else
      yield
    end
  end

  it "should handle the loss of a client" do
    EM.run do
      @cons = 0
      @server.start do |client|
        @cons += 1
        if (@cons == 2)
          @connection1.stop
        end
        client.errback do
          @cons -= 1
          if @cons == 1
            EM.stop
          end
        end
      end

      @connection1.start
      @connection2.start

      wait_for_connections(2, 10) do
        @connection1.stop
        wait_for_connections(1, 10) do
          @cons.should == 1
          EM.stop
        end
      end
    end
  end

  it "should call errorback when port is already in use" do
    @errback_called = false

    thread = start_reactor
    EM.run do
      @blocked_server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))

      @blocked_server.errback do |e|
        @errback_called = true
        @err_message = e.message
      end

      @server.start
      @blocked_server.start
    end

    wait_for{@errback_called}
    stop_reactor(thread)

    @errback_called.should be_true
    @err_message.include?("acceptor").should be_true
  end

  it "handles no method calls on client" do
    @errback_called = false
    @err_messages = []
    @expected_messages = ["received unexpected message :not_a_method", "Connection Failure"]

    thread = start_reactor
    EM.run do
      @connection1.errback do |e|
        @errback_called = true
        @err_messages << e.message
      end
      @server.start
      @connection1.start do
        @connection1.not_a_method(nil)
      end
    end
    wait_for{@errback_called}
    stop_reactor(thread)

    @errback_called.should be_true
    @err_messages[0].include?(@expected_messages[0]).should be_true
    @err_messages[1].include?(@expected_messages[1]).should be_true
    @err_messages.should have(2).items
  end

  it "handles no method calls on server" do
    @errback_called = false
    @err_messages = []
    @expected_messages = ["received unexpected message :not_a_method", "Connection Failure", "Connection Failure"]

    thread = start_reactor
    EM.run do
      @server.errback do |e|
        @errback_called = true
        @err_messages << e.message
      end

      @server.start do |connection|
        connection.not_a_method
      end

      @connection1.start

    end
    wait_for{@errback_called}
    stop_reactor(thread)

    @errback_called.should be_true
    @err_messages[0].include?(@expected_messages[0]).should be_true
    @err_messages[1].include?(@expected_messages[1]).should be_true
    @err_messages.should have(3).items
  end

  it "removes unbinded connection from connections ivar" do
    thread = start_reactor
    EM.run do
      @server.start
      @connection1.start
    end
    wait_for{false}
    @server.connections.size.times do
      @server.connections.first.unbind
    end
    @server.connections.should have(0).items
    stop_reactor(thread)
  end

  it "removes one unbinded connection from connections ivar of size two" do
    thread = start_reactor
    EM.run do
      @server.start
      @connection1.start
      @connection2.start
    end
    wait_for{false}
    2.times do
      @server.connections.first.unbind
    end
    @server.connections.should have(2).items
    stop_reactor(thread)
  end

  it "does not error out after calling stop twice consecutively" do
    thread = start_reactor

    EventMachine.should_receive(:stop_server).once

    @server.start

    @connected = false
    @connection1.start do
      @connected = true
    end

    wait_for{@connected}

    @server.stop
    @server.stop

    stop_reactor(thread)
  end

end
