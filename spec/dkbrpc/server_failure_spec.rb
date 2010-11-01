require 'dkbrpc/server'
require 'dkbrpc/connection'
require 'dkbrpc/insecure_method_call_error'
require 'socket'

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Server Failures" do

  CONNECTION_ERROR      = "Connection Failure"
  NO_METHOD_ERROR       = "received unexpected message :not_a_method"
  INSECURE_METHOD_ERROR = "Remote client attempts to call method class, but was denied."

  before(:all) do
    @port = 9441
  end

  before(:each) do
    @server = Dkbrpc::Server.new("127.0.0.1", @port, mock("server"))
    @connection1 = Dkbrpc::Connection.new("127.0.0.1", @port, mock("client"))
    @connection2 = Dkbrpc::Connection.new("127.0.0.1", @port, mock("client"))
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

  def check_messages(size, actual, expected)
    actual.should have(size).items
    (0...size).each { |i| actual[i].include?(expected[i]).should be_true }
  end

  def run_server_failure(blocks)
    server_block   = blocks[:server]
    client_block   = blocks[:client]
    server_errback = blocks[:server_errback]
    client_errback = blocks[:client_errback]
    connected = false
    errbacked = false
    thread = start_reactor
    EM.schedule do
      @server.errback      { |e| server_errback.call(e) if server_errback; errbacked = true }
      @server.start        { |connection| server_block.call(connection) if server_block }
      @connection1.errback { |e| client_errback.call(e) if client_errback; errbacked = true }
      @connection1.start   { client_block.call(@connection1) if client_block; connected = true }
    end
    wait_for{connected}
    wait_for{errbacked}
    stop_reactor(thread)
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
    errback_called = false
    err_message = ""

    thread = start_reactor
    EM.run do
      blocked_server = Dkbrpc::Server.new("127.0.0.1", @port, mock("server"))

      blocked_server.errback do |e|
        errback_called = true
        err_message = e.message
      end

      @server.start
      blocked_server.start
    end

    wait_for{errback_called}
    stop_reactor(thread)

    errback_called.should be_true
    err_message.include?("acceptor").should be_true
  end

  it "handles no method call on server side" do
    err_messages = []
    expected_messages = [NO_METHOD_ERROR, CONNECTION_ERROR]
    client_errback_block = Proc.new { |e| err_messages << e.message }
    client_block = Proc.new { |connection| connection.not_a_method }
    run_server_failure({:client => client_block, :client_errback => client_errback_block})
    check_messages(2, err_messages, expected_messages)
  end

  it "handles no method call on client side" do
    err_messages = []
    expected_messages = [NO_METHOD_ERROR, CONNECTION_ERROR, CONNECTION_ERROR]
    server_errback_block = Proc.new { |e| err_messages << e.message }
    server_block = Proc.new { |connection| connection.not_a_method }
    run_server_failure({:server => server_block, :server_errback => server_errback_block})
    check_messages(3, err_messages, expected_messages)
  end

  it "handles insecure method call on server side" do
    err_messages = []
    expected_messages = [INSECURE_METHOD_ERROR, CONNECTION_ERROR, CONNECTION_ERROR]

    client_block = Proc.new do |connection|
      connection.instance_eval("undef class")
      connection.class do |result|
        result.should be_a(InsecureMethodCallError)
      end
    end
  
    client_errback_block = Proc.new { |e| err_messages << e.message }
    run_server_failure({:server => client_block, :server_errback => client_errback_block})
    check_messages(3, err_messages, expected_messages)
  end
  
  it "handles insecure method call on client side" do
    err_messages = []
    expected_messages = [INSECURE_METHOD_ERROR, CONNECTION_ERROR, CONNECTION_ERROR]

    server_block = Proc.new do |connection|
      connection.instance_eval("undef class")
      connection.class do |result|
        result.should be_a(InsecureMethodCallError)
      end
    end

    server_errback_block = Proc.new { |e| err_messages << e.message }
    run_server_failure({:server => server_block, :server_errback => server_errback_block})
    check_messages(3, err_messages, expected_messages)
  end

  it "removes unbinded connection from connections ivar" do
    thread = start_reactor
    connected = false
    EM.schedule do
      @server.start
      @connection1.start {connected = true}
    end
    wait_for{connected}
    @server.connections.size.times { @server.connections.first.unbind }
    @server.connections.should have(0).items
    stop_reactor(thread)
  end
  
  it "removes one unbinded connection from connections ivar of size two" do
    thread = start_reactor
    connected = false
    @server.start
    @connection1.start
    @connection2.start {connected = true}
    wait_for{connected}
    2.times { @server.connections.first.unbind }
    @server.connections.should have(2).items
    stop_reactor(thread)
  end

  it "does not error out after calling stop twice consecutively" do
    EventMachine.should_receive(:stop_server).once
    thread = start_reactor
    connected = false
    @server.start
    @connection1.start {connected = true}
    wait_for{connected}
    @server.stop
    @server.stop
    stop_reactor(thread)
  end
  
  it "executes all errback blocks when exception is thrown on client side" do
    @errback1 = false
    @errback2 = false
    @errback3 = false
    @errback4 = false

    server_block = Proc.new do |connection|
      connection.errback { |e| @errback1 = true }
      connection.errback { |e| @errback2 = true }
      connection.not_a_method
    end

    client_block = Proc.new do |connection|
      connection.errback { |e| @errback3 = true }
      connection.errback { |e| @errback4 = true }
    end

    run_server_failure({:server => server_block,
                        :client => client_block})

    @errback1.should be_true
    @errback2.should be_true
    @errback3.should be_true
    @errback4.should be_true
  end

  it "executes all errback blocks when exception is thrown on server side" do
    @errback1 = false
    @errback2 = false
    @errback3 = false
    @errback4 = false

    server_block = Proc.new do |connection|
      connection.errback { |e| @errback1 = true }
      connection.errback { |e| @errback2 = true }
    end

    client_block = Proc.new do |connection|
      connection.errback { |e| @errback3 = true }
      connection.errback { |e| @errback4 = true }
      connection.not_a_method
    end

    run_server_failure({:server => server_block,
                        :client => client_block})

    @errback1.should be_true
    @errback2.should be_true
    @errback3.should be_true
    @errback4.should be_true
  end

end
