require 'rubygems'
require 'eventmachine'

class ClientApi
  def set_availability(state)
    puts ("availability = #{state}")
    send_response(true)
  end

  def configure(hash)
    puts ("configuration:  #{hash}")
    send_response(true)
  end
end

api = ClientApi.new
remote_server = DougConnection.new("localhost", 9441, api)
remote_server.hello("dougs") do |response|
  puts response
end



###################################

class ServerApi
  attr_accessor :remote_clients

  def initialize
    remote_clients = {}
  end

  def connection_made(remote_client)

  end
  
  def hello(remote_client, name)
    @remote_clients[name] = remote_client
    send_response("how are you #{name}?")
  end
end


api = ServerApi.new
Dkbrpc::Server.new("0.0.0.0", 9441, api)



api.remote_clients["dougs"].configure({:on => true, :it => "does"}) do |response|
  puts "Configure response:  #{response}"
end
