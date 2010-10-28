require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "dkbrpc/responder"
require "dkbrpc/incoming_connection"

include Dkbrpc

describe Responder do
  before(:each) do
    @responder = Responder.new(IncomingConnection, "00000001")
  end

  it "sets id on initialize" do
    @responder.message_id.should == "00000001"
  end

  it "sets incoming connnection on initialize" do
    @responder.incoming_connection.should == IncomingConnection
  end

  it "calls incoming_connection#reply with stored message_id" do
    @responder.incoming_connection.should_receive(:reply).with("00000001", "Hello Doug")
    @responder.reply("Hello Doug")
  end
end
