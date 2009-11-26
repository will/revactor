require '../lib/revactor'
require 'tuplesclient'

class NodeManager
  extend Actorize
  def initialize
    @ts = TupleClient::get_ts
    receive_loop
  end

  def get_messages
    loop do
      take_all { |msg| p msg }
      puts "..."
      Actor.sleep 2
    end
  end
  call :get_messages, :when => :get_messages
 
  private
   
  def take_all
    raise ArgumentError unless block_given?
    while msg = take_message
      yield msg
    end
  end
  
  def take_message
    begin
      node, message = @ts.take( [:node_1, nil], 0) 
    rescue Rinda::RequestExpiredError
      message = nil
    end
    message
  end
end

manager = NodeManager.spawn
manager << :get_messages
Actor.tick

loop { Actor.sleep 20 }