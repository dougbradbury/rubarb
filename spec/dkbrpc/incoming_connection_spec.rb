require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "dkbrpc/incoming_connection"
require "dkbrpc/remote_call"

describe Dkbrpc::IncomingConnection do
  include Dkbrpc::RemoteCall
  include Dkbrpc::IncomingConnection
  attr_reader :api

  class TestApi
    attr_accessor :dodo
    def amethod(responder, dodo)
      @dodo = dodo
    end
  end

  before(:each) do
    @api = TestApi.new
  end

  it "should receive message " do
    receive_message(marshal_call(:amethod, "goo"))
    @api.dodo.should == "goo"
  end

  it "should receive reply with exception when a non-existent method is called" do
    self.should_receive(:reply).with do |exception|
      exception.message.include?("undefined method").should == true
    end
    receive_message(marshal_call(:not_a_method, "foo"))
    @api.dodo.should_not == "foo"
  end
end
