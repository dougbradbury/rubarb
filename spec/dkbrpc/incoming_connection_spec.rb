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
  
  it "should receive message " do
    @api = TestApi.new
    receive_message(marshal_call(:amethod, "goo"))
    @api.dodo.should == "goo"
  end

end