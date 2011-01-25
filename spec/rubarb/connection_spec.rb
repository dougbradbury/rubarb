require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubarb/server'
require "rubarb/connection"
require "rubarb/remote_call"
require "rubarb/default"

describe Rubarb::Connection do
  CUSTOM_INSECURE_METHODS = [:==, :===, :=~]

  before(:all) do
    @reactor = start_reactor
  end

  after(:all) do
    stop_reactor(@reactor)
  end

  it "has an instance of Rubarb::Id" do
    @connection = Rubarb::Connection.new("host", "port", "api")
    @connection.msg_id_generator.class.should == Rubarb::Id
  end

  it "should stop" do
    @result = "blah"
    @connection = Rubarb::Connection.new("host", "port", "api")
    @connection.stop do |result|
      @result = result
    end

    wait_for { @result == false }
    @result.should == false
  end

  describe "with client and server connected" do
    
    def connect(connection)
      connected = false
      connection.start do
        connected = true
      end
      wait_for { connected }
      return connection
    end
    
    before(:all) do
      @server = Rubarb::Server.new("127.0.0.1", 9441, mock("server"))
      @server.start
      @connection = connect(Rubarb::Connection.new("127.0.0.1", 9441, mock("client")))
    end

    it "sets an instance of Rubarb::Id to remote_connection" do
      @connection.remote_connection.msg_id_generator.class.should == Rubarb::Id
    end

    it "sets an instance of insecure_methods to remote_connection" do
      @connection.remote_connection.insecure_methods.class.should == Array
    end

    it "has default insecure methods" do
      @connection.remote_connection.insecure_methods.should == Rubarb::Default::INSECURE_METHODS
    end

    it "can accept custom insecure methods" do
      connection = connect(Rubarb::Connection.new("127.0.0.1", 9441, mock("client"), CUSTOM_INSECURE_METHODS))
      connection.remote_connection.insecure_methods.should == CUSTOM_INSECURE_METHODS
    end

    it "should stop after it's connected" do
      connection = connect(Rubarb::Connection.new("127.0.0.1", 9441, mock("client")))

      @result = "boo"
      connection.stop do |result|
        @result = result
      end
      wait_for{@result == true}
      @result.should == true
    end

    it "doesn't exit the reactor loop when an exception occurs in Connection::method_missing" do
      connection = connect(Rubarb::Connection.new("127.0.0.1", 9441, mock("client")))
      error = nil
      connection.errback {|e| error = e}
      connection.remote_connection.should_receive(:remote_call).and_raise("Blah")
      
      connection.foo
      wait_for{error != nil}
      
      error.to_s.should == "Blah"
      EM.reactor_running?.should == true
    end

    it "should catch exceptions from connect" do
      connection = Rubarb::Connection.new("127.0.0.1", 9441, mock("client"))
      EventMachine.stub!(:connect).and_raise("Internal Java error")
      errback_called = false
      connection.errback do |e|
        e.message.should == "Internal Java error"
        errback_called = true
      end
      connection.start

      wait_for{errback_called}
      
    end

  end

end

describe Rubarb::OutgoingHandler do
  include Rubarb::OutgoingHandler
  include Rubarb::RemoteCall

  before(:each) do
    @sent_data = ""
    self.stub!(:send_data) do |data|
      @sent_data << data
    end
    post_init
  end

  it "should send type on start" do
    connection_completed
    @sent_data.should == "4"
  end

  it "should open an outgoing connection with connection id" do
    connection_completed
    @host = "1.2.3.4"
    @port = 2321
    EventMachine.should_receive(:connect).with("1.2.3.4", 2321, Rubarb::IncomingHandler)
    receive_data("0000")
    receive_data("0001")
  end

  it "should send marshaled calls" do
    @callback = {}
    @sent_msg = ""
    id_generator = mock("id")
    id_generator.stub!(:next).and_return("00000001")
    @msg_id_generator = id_generator
    self.stub!(:send_message) { |msg| @sent_msg << msg }
    remote_call(:foo, "bary")
    @sent_msg.should == marshal_call("00000001", :foo, "bary")
  end
end

describe Rubarb::IncomingHandler do
  include Rubarb::IncomingHandler

  before(:each) do
    @sent_data = ""
    self.stub!(:send_data) do |data|
      @sent_data << data
    end
    post_init
  end

  it "should send type and id on connection made" do
    @id = "00000001"
    connection_completed
    @sent_data.should == "500000001"
  end

  it "should call back when finished" do
    callback = false
    @on_connection = Proc.new { callback = true }
    @id = "00000001"

    connection_completed
    callback.should == false

    receive_message(@id)
    callback.should == true
  end

  it "should errback if ids do not match" do
    errback_msg = false
    @parent = mock("parent")
    @parent.should_receive(:call_errbacks) do |error|
      error.message.should == "Handshake Failure"
    end

    @parent.should_receive(:connection_completed).with(self)

    @id = "00000001"

    connection_completed
    receive_message("00000004")
  end
end
