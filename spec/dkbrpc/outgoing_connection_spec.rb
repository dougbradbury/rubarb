require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "dkbrpc/outgoing_connection"
require "dkbrpc/remote_call"

describe Dkbrpc::OutgoingConnection do
  include Dkbrpc::RemoteCall
  include Dkbrpc::OutgoingConnection

  before(:each) do
    @callback = {}
    set_id("00000001")
  end

  def set_id(id)
    id_generator = mock("id")
    id_generator.stub!(:next).and_return(id)
    @msg_id_generator = id_generator
  end

  it "sets callback" do
    block = Proc.new { puts "Hello" }
    self.should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    @callback["00000001"].should == block
  end

  it "executes callback block when receive_message is called" do
    block = Proc.new do |v|
      @value = v
    end
    should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    receive_message(marshal_call("00000001", "value"))
    @value.should == "value"
  end

  it "does not execute callback block when receive_message is called with an exception" do
    block = Proc.new { puts "Hello" }
    should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    should_receive(:call_errbacks)
    @callback.should_not_receive(:call)
    receive_message(marshal_call("00000001", Exception.new))
  end

  it "saves error message when receive_message is called with an exception" do
    exception = Exception.new("Hello")
    error = nil
    @errbacks = [Proc.new { |e| error = e }]
    block = Proc.new { puts "Hello" }

    should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
    stub!(:call_errbacks).and_return(@errbacks.first.call(exception))
    @callback.stub!(:call)

    receive_message(marshal_call("00000001", exception))

    error.class.should == Exception
    error.message.should == (exception.message)
  end

  it "has a message id argument for marshal_call" do
    block = Proc.new { puts "Hello" }
    should_receive(:marshal_call).with("00000001", :amethod, "asdf")
    self.should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
  end

  it "generates a message id" do
    set_id("00000002")
    block = Proc.new { puts "Hello" }
    should_receive(:marshal_call).with("00000002", :amethod, "asdf")
    should_receive(:send_message)
    remote_call(:amethod, "asdf", &block)
  end

  it "pushes callback block to callback hash with id as key" do
    @callback = {}
    set_id("00000001")
    block = Proc.new { puts "Hello" }
    stub!(:send_message)
    remote_call(:amethod, "asdf", &block)
    @callback["00000001"].should == block
  end

  it "calls the corresponding block with given id" do
    block = mock("block")
    block.should_receive(:call).with("asdf")
    @callback = { "00000002" => block }
    receive_message(marshal_call("00000002", "asdf"))
  end

  it "removes callback from hash after call" do
    block = mock("block")
    block.should_receive(:call).with("asdf")
    @callback = { "00000002" => block }
    receive_message(marshal_call("00000002", "asdf"))
    @callback.should have(0).items
  end
end
