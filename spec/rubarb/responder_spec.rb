require 'spec_helper'
require "rubarb/responder"
require "rubarb/incoming_connection"
require "rubarb/server"

include Rubarb

class MockHandler
  include Listener
  include IncomingConnection
end

describe Responder do
  before(:each) do
    @responder = Responder.new(MockHandler.new, "00000001")
  end

  it "sets id on initialize" do
    @responder.message_id.should == "00000001"
  end

  it "sets handler on initialize" do
    @responder.handler.class.should == MockHandler
  end

  it "calls handler#reply with stored message_id" do
    @responder.handler.should_receive(:reply).with("00000001", "Hello Doug")
    @responder.reply("Hello Doug")
  end

  it "calls handler's conn_id" do
    @responder.handler.should_receive(:conn_id)
    @responder.conn_id
  end
end
