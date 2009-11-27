require '../lib/revactor'
require 'tuplesclient'

class NodeManager
  extend Actorize
  def initialize
    @ts = TupleClient::get_ts
    @actors = {}
    receive_loop
  end

  def init
    Actor.current << :get_messages
  end
  call :init, :when => :init
  
  def get_messages
    take_all do |msg|
      p msg
      Actor.current << msg      
    end
    puts "... #{@actors.inspect}"
    
    Actor.current << :get_messages
    Actor.sleep 2
  end
  call :get_messages, :when => :get_messages
  
  def create_actor(_, actor_name, class_name)
    @actors[actor_name] = Module::const_get(class_name).spawn
  end
  call :create_actor, :when => T[:create_actor]
  
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