require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "dkbrpc/connection"
require "dkbrpc/remote_call"

describe Dkbrpc::OutgoingHandler do
  include Dkbrpc::OutgoingHandler
  include Dkbrpc::RemoteCall

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
    EventMachine.should_receive(:connect).with("1.2.3.4", 2321, Dkbrpc::IncommingHandler)
    receive_data("0000")
    receive_data("0001")
  end

  it "should send marshalled calls" do
    @sent_msg = ""
    self.stub!(:send_message) {|msg| @sent_msg << msg}
    remote_call(:foo, "bary")
    @sent_msg.should == marshal_call(:foo, "bary")
  end

end


describe Dkbrpc::IncommingHandler do
  include Dkbrpc::IncommingHandler

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
    pending("does not work") do
      callback = false
      @on_connection = Proc.new {callback = true}
      @id = "00000001"
      
      connection_completed
      callback.should == false
      
      receive_data "00000001"
      callback.should == true
    end
  end
end