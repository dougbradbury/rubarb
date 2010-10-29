require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'dkbrpc/server'
require 'dkbrpc/connection'

describe "Server to Client communication and response" do

  class TestClientApi
    def name(responder)
      responder.reply("Doug")
    end
  end

  before(:each) do
    @reactor = start_reactor
    @server_api = mock("server")
    @client_api = TestClientApi.new

    @server = Dkbrpc::Server.new("127.0.0.1", 9441, @server_api)
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, @client_api)
  end

  after(:each) do
    stop_reactor(@reactor)
  end

  it "should communicate with the client" do
    @callback_called = false

    @server.start do |new_client|
      new_client.name do|result|
        result.should == "Doug"
        @callback_called = true
      end
    end

    @connection.start

    wait_for {@callback_called}

  end

end

describe "Client to Server communication and response" do
  class TestReply
    attr_reader :message

    def initialize(name)
      @message = "How are you #{name}, my friend?"
    end
  end

  class TestServerApi
    attr_reader :hi_called
    def hi(responder)
      responder.reply("how are you?")
      @hi_called = true
    end

    def hello(responder, name)
      responder.reply("how are you #{name}?")
    end

    def hello_friend(responder, name)
      responder.reply(TestReply.new(name))
    end

    attr_reader :conn_id
    def save_id(responder)
      @conn_id = responder.conn_id
      responder.reply(nil)
    end
  end

  before(:each) do
    @reactor = start_reactor
    @server_api = TestServerApi.new
    @client_api = mock("client")

    @server = Dkbrpc::Server.new("127.0.0.1", 9441, @server_api)
    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, @client_api)
  end

  after(:each) do
    stop_reactor(@reactor)
  end

  it "without a callback" do
    @server.start

    @connection.start do
      @connection.hi
    end

    wait_for {@server_api.hi_called}
  end
  
  it "without parameters" do
    @callback_called = false
    @server.start

    @connection.start do
      @connection.hi do |response|
        response.should == "how are you?"
        @callback_called = true
      end
    end

    wait_for {@callback_called}
  end

  it "with parameters" do
    @callback_called = false
    @server.start
    @connection.start do
      @connection.hello("Doug") do |response|
        @callback_called = true
        response.should == "how are you Doug?"
      end
    end
    wait_for {@callback_called}
  end

  it "with complex response" do
    @callback_called = false
    @server.start
    @connection.start do
      @connection.hello_friend("Doug") do |response|
        @callback_called = true
        response.message.should == "How are you Doug, my friend?"
      end
    end

    wait_for {@callback_called}
  end

  it "can get connection id on connection" do
    @callback_called = false
    @new_connection_id = nil
    @server.start do |new_connection|
      @new_connection_id = new_connection.conn_id
    end

    @connection.start do
      @connection.save_id do |response|
        @callback_called = true
      end
    end

    wait_for {@callback_called}
    @server_api.conn_id.should == @new_connection_id
  end

end
