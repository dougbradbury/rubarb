require 'dkbrpc/server'
require 'dkbrpc/connection'
require 'socket'

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Server Failures" do

  it "should handle the loss of a client" do
    EM.run do
      @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
      @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
      @connection2 = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))

      @cons = 0
      @server.start do |client|
        @cons += 1
        if (@cons == 2)
          @connection.stop
        end
        client.errback do
          @cons -= 1
          if @cons == 1
            EM.stop
          end
        end
      end

      @connection.start
      @connection2.start

      wait_for_connections(2, 10) do
        @connection.stop
        wait_for_connections(1, 10) do
          @cons.should == 1
          EM.stop
        end
      end
    end
  end
  
  it "should call errorback when port is already in use" do
    @errback_called = false
    
    thread = Thread.new do
      EM.run do
        
        @server = Dkbrpc::Server.new("127.0.0.1", 7778, mock("server"))
        @blocked_server = Dkbrpc::Server.new("127.0.0.1", 7778, mock("server"))
            
        @blocked_server.errback do |e|
          @errback_called = true
          @err_message = e.message
        end
        
        @server.start
        @blocked_server.start
      end
    end
            
    wait_for{@errback_called}
    EM.stop
    thread.join
    
    @errback_called.should be_true
    @err_message.should == "no acceptor"
  end

  it "handles no method calls on client" do
    @errback_called = false
    @err_messages = []
    @expected_messages = ["received unexpected message :not_a_method", "Connection Failure"]

    thread = Thread.new do
      EM.run do
        @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
        @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))

        @connection.errback do |e|
          @errback_called = true
          @err_messages << e.message
        end

        @server.start
        @connection.start do
          @connection.not_a_method(nil)
        end
      end
    end
    wait_for{@errback_called}
    EM.stop
    thread.join

    @errback_called.should be_true
    @err_messages[0].include?(@expected_messages[0]).should be_true
    @err_messages[1].include?(@expected_messages[1]).should be_true
  end

#  it "handles no method calls on server" do
#    @errback_called = false
#    @err_messages = []
#    @expected_messages = ["received unexpected message :not_a_method", "Connection Failure"]
#
#    thread = Thread.new do
#      EM.run do
#        @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
#        @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
#
#        @server.errback do |e|
#          @errback_called = true
#          @err_messages << e.message
#        end
#
#        @server.start
#        @connection.start
#
#        @server.not_a_method
#      end
#    end
#    wait_for{@errback_called}
#    EM.stop
#    thread.join
#
#    @errback_called.should be_true
#    @err_messages[0].include?(@expected_messages[0]).should be_true
#    @err_messages[1].include?(@expected_messages[1]).should be_true
#  end

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

end
