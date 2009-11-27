require '../lib/revactor'
require 'tuplesclient'

class NodeManager
  extend Actorize
  def initialize
    @ts = TupleClient::get_ts
    receive_loop
  end

  def init
    Actor.current << :get_messages
  end
  call :init, :when => :init
  
  def get_messages
    take_all { |msg| p msg }
    puts "..."
    Actor.current << :get_messages
    Actor.sleep 2
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
manager << :init

loop { Actor.sleep 2 }