require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'dkbrpc/server'
require "dkbrpc/remote_call"
require 'dkbrpc/connection'

include Dkbrpc

describe Listener do
  include RemoteCall

  before(:each) do
    self.extend(Listener)
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
    self.stub!(:send_message) do |message|
      @sent_message = message
    end
    receive_data("5")
    receive_data("00000005")
    @sent_message.should == "00000005"
    @conn_id.should == "00000005"
  end
end

describe Dkbrpc::Server do
  it "has an instance of Dkbrpc::Id" do
    server = Server.new("host", "port", "api")
    server.conn_id_generator.class.should == Dkbrpc::Id
  end

  it "has an instance of Dkbrpc::Id for message ids" do
    server = Server.new("host", "port", "api")
    server.msg_id_generator.class.should == Dkbrpc::Id
  end

  it "sets instance of Dkbrpc::Id to each connection for connection ids" do
    thread = start_reactor
    @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
    EM.run do
      @server.start
      @connection.start
    end
    wait_for{false}
    generator_class = @server.connections.first.conn_id_generator.class
    stop_reactor(thread)
    generator_class.should == Dkbrpc::Id
  end

  it "sets instance of Dkbrpc::Id to each connection for message ids" do
    thread = start_reactor
    @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
    EM.run do
      @server.start
      @connection.start
    end
    wait_for{false}
    generator_class = @server.connections.first.msg_id_generator.class
    stop_reactor(thread)
    generator_class.should == Dkbrpc::Id
  end

  it "sets an empty callback hash to each connection" do
    thread = start_reactor
    @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
    EM.run do
      @server.start
      @connection.start
    end
    wait_for{false}
    callback = @server.connections.first.callback
    stop_reactor(thread)
    callback.class.should == Hash
    callback.should have(0).items
  end

  it "makes sure @conn_id_generator#next is called in handle_incoming" do
    self.extend(Listener)
    id_generator = mock("id")
    id_generator.stub!(:next).and_return("00000001")
    @conn_id_generator = id_generator
    self.should_receive(:send_data).with("00000001")
    self.stub!(:switch_protocol)
    handle_incoming
    @conn_id.should == "00000001"
  end

  it "makes two callback calls" do
    thread = start_reactor

    @server = Dkbrpc::Server.new("127.0.0.1", 9441, TestApi.new)
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
    EM.run do
      @server.start
      @connection.start do
        @connection.get_one do |counter|
          counter.should == 1
        end
        @connection.get_two do |counter|
          counter.should == 2
        end
      end
    end
    wait_for{false}
    stop_reactor(thread)
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
