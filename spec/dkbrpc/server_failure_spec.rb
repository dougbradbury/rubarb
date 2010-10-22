require 'dkbrpc/server'
require 'dkbrpc/connection'

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Server Failures" do
  before(:each) do
#    @reactor = start_reactor
  end

  after(:each) do
#    stop_reactor(@reactor)
  end

  it "should handle the loss of a client" do
    EM.run do
      @server = Dkbrpc::Server.new("127.0.0.1", 9441, mock("server"))
      @connection = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))
      @connection2 = Dkbrpc::Connection.new("127.0.0.1", 9441, mock("client"))


      @cons = 0
      @server.start do |client|
        @cons += 1
        if (@cons == 2)
          @connection.stop
        end
        client.errback do
          puts "errback"
          @cons -= 1
          if @cons == 1
            EM.stop
          end
        end
      end

      @connection.start
      @connection2.start

      wait_for_connections(2, 10) do
        puts "stopping connection"
        @connection.stop
        wait_for_connections(1, 10) do
          @cons.should == 1
          EM.stop
        end
      end

    end

  end

  def wait_for_connections(n, ttl, &block)
    puts "waiting #{n} , TTL:  #{ttl}"
    if ttl <= 0
      fail("TTL expired")
    end

    if @cons != n
      EventMachine.add_periodic_timer(0.1) do
        wait_for_connections(n, ttl -1, &block )
      end
    else
      yield
    end
  end

end
