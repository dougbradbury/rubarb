require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'dkbrpc/server'
require 'dkbrpc/connection'


#describe  "Server to Client communication and response" do
#
#  class TestServerApi
#    def hello(responder)
#
#    end
#  end
#
#  class TestClientApi
#    def welcome(responder)
#      responser.
#    end
#  end
#
#  before(:each) do
#    @reactor = start_reactor
#    @server_api = TestServerApi.new
#    @client_api = mock("client")
#
#    @server = Dkbrpc::Server.new("127.0.0.1", 9441, @server_api)
#    @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, @client_api)
#  end
#
#  after(:each) do
#    stop_reactor(@reactor)
#  end
#
#end

describe "Client to Server communication and response" do
  class TestReply
    attr_reader :message
    def initialize(name)
      @message = "How are you #{name}, my friend?"
    end
  end

  class TestServerApi
    def hi(responder)
      responder.reply("how are you?")
    end

    def hello(responder, name)
      responder.reply("how are you #{name}?")
    end

    def hello_friend(responder, name)
      responder.reply(TestReply.new(name))
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

  it "without parameters" do
    @callback_called = false
    @server.start
    @connection.start do
      @connection.hi do |response|
        @callback_called = true
        response.should == "how are you?"
      end
    end

    while (!@callback_called)
      Thread.pass
    end
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

    while (!@callback_called)
      Thread.pass
    end

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

    while (!@callback_called)
      Thread.pass
    end

  end

end