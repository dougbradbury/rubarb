require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubarb/server'
require "rubarb/remote_call"
require 'rubarb/connection'
require 'rubarb/default'

include Rubarb

describe Listener do
  include RemoteCall

  before(:each) do
    extend(Listener)
    @sent_data = ""
    self.stub!(:send_data) do |data|
      @sent_data = data
    end
    post_init
  end

  def set_id(id)
    id_generator = mock("id")
    id_generator.stub!(:next).and_return(id)
    @conn_id_generator = id_generator
  end

  it "should generate and send connection ID" do
    set_id("00000001")
    receive_data("4")
    @sent_data.should == "00000001"
  end

  it "should receive another connection" do
    stub!(:send_message) do |message|
      @sent_message = message
    end
    receive_data("5")
    receive_data("00000005")
    @sent_message.should == "00000005"
    @conn_id.should == "00000005"
  end

  class OtherProtocol

    attr_reader :buffer, :connection

    def handle_connection(buffer, connection)
      @buffer = buffer
      @connection = connection
    end

  end

  it "should handle other protocols" do
    @external_protocol = OtherProtocol.new
    receive_data("1")

    @external_protocol.buffer.should == "1"
    @external_protocol.connection.should_not be_nil
  end
end

describe Rubarb::Server do

  before(:each) do
    @reactor_thread = nil
  end

  after(:each) do
    stop_reactor(@reactor_thread) if @reactor_thread
  end

  it "has an instance of Rubarb::Id" do
    server = Server.new("host", "port", "api")
    server.conn_id_generator.class.should == Rubarb::Id
  end

  it "has an instance of Rubarb::Id for message ids" do
    server = Server.new("host", "port", "api")
    server.msg_id_generator.class.should == Rubarb::Id
  end

  it "has an instance of insecure_methods" do
    server = Server.new("host", "port", "api")
    server.insecure_methods.class.should == Array
  end

  it "has default insecure_methods" do
    server = Server.new("host", "port", "api")
    server.insecure_methods.should == Rubarb::Default::INSECURE_METHODS
  end

  it "accepts custom insecure methods on initilization" do
    server = Server.new("host", "port", "api", [:==, :===, :=~])
    server.insecure_methods.should == [:==, :===, :=~]
  end

  def connect
    @reactor_thread = start_reactor
    connected = false
    @server = Rubarb::Server.new("127.0.0.1", 9441, mock("server"))
    @connection = Rubarb::Connection.new("127.0.0.1", 9441, mock("client"))
    EM.schedule do
      @server.start { |client| @client = client }
      EM.next_tick {@connection.start { connected = true } }
    end
    wait_for { connected }
    connected.should == true
  end

  it "sets instance of Rubarb::Id to each connection for connection ids" do
    connect
    generator_class = @server.connections.first.conn_id_generator.class
    generator_class.should == Rubarb::Id
  end

  it "sets instance of Rubarb::Id to each connection for message ids" do
    connect
    generator_class = @server.connections.first.msg_id_generator.class
    generator_class.should == Rubarb::Id
  end

  it "sets instance of insecure_methods on each connection" do
    connect
    insecure_methods = @server.connections.first.insecure_methods
    insecure_methods.should == Rubarb::Default::INSECURE_METHODS
  end

  it "makes sure @conn_id_generator#next is called in handle_incoming" do
    extend(Listener)
    id_generator = mock("id")
    id_generator.stub!(:next).and_return("00000001")
    @conn_id_generator = id_generator
    should_receive(:send_data).with("00000001")
    stub!(:switch_protocol)
    handle_incoming
    @conn_id.should == "00000001"
  end

  it "makes two overlapping calls" do
    @reactor_thread = start_reactor
    connected = false

    @server = Rubarb::Server.new("127.0.0.1", 9441, TestApi.new)
    @connection = Rubarb::Connection.new("127.0.0.1", 9441, mock("client"))
    EM.run do
      @server.start
      @connection.start do
        @connection.get_one do |counter|
          counter.should == 1
        end
        @connection.get_two do |counter|
          counter.should == 2
        end
        connected = true
      end
    end
    wait_for { connected }
  end

  it "catches exceptions that occur during a remote call to client" do
    connect
    error = nil
    @client.remote_connection.errbacks << proc { |e| error = e }
    @client.remote_connection.should_receive(:remote_call).and_raise("Blah")

    @client.foo
    wait_for { error != nil }

    error.to_s.should == "Blah"
    EM.reactor_running?.should == true
  end

  it "should catch exceptions in starting server" do
    EventMachine.stub!(:start_server).and_raise("EMReactor Exception")

    @reactor_thread = start_reactor
    done = false

    @server = Rubarb::Server.new("127.0.0.1", 9441, TestApi.new)
    @server.errback do |error|
      error.message.should == "EMReactor Exception"
      done = true
    end

    @server.start

    wait_for { done }
    done.should == true

  end
end

class TestApi
  def get_one(responder)
    EM.add_timer(0.5) { responder.reply(1) }
  end

  def get_two(responder)
    responder.reply(2)
  end
end
