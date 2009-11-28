require '../lib/revactor'
require 'tuplesclient'

class NodeManager
  extend Actorize
  def initialize(node_name)
    @node_name = node_name
    @ts = TupleClient::get_ts
    @actors = {:manager => Actor.current}
    Actor[:manager] = Actor.current
    receive_loop
  end

  def init
    Actor.current << :get_messages
  end
  call :init, :when => :init
  
  def get_messages
    take_all do |msg|
      actor, message = msg
      local_actor = @actors.fetch(actor) { |fail| puts "No such actor #{fail}"}
      local_actor << message if local_actor
    end
    
    puts "[#{@node_name}]\t#{@actors.inspect}"
    @actors[:manager] << :get_messages
    Actor.sleep 2
  end
  call :get_messages, :when => :get_messages
  
  def create_actor(_, actor_name, class_name)
    @actors[actor_name] = Module::const_get(class_name).spawn
  end
  call :create_actor, :when => T[:create_actor]
  
  def remote_create(_, node, actor_name, class_name)
    _remote_send(node, :manager, [:create_actor, actor_name, class_name])
  end
  call :remote_create, :when => T[:remote_create]
  
  def remote_send(_, node, actor, message)
    _remote_send(node, actor, message)
  end
  call :remote_send, :when => T[:remote_send]
  
  private
   
  def take_all
    raise ArgumentError unless block_given?
    while msg = take_message
      yield msg
    end
  end
  
  def take_message
    begin
      node, message = @ts.take( [@node_name, nil], 0) 
    rescue Rinda::RequestExpiredError
      message = nil
    end
    message
  end
  
  def _remote_send(node, actor, message)
    @ts.write [node, [actor, message] ]
  end
end


class RemoteActor
  extend Actorize
  def initialize(actor_class, remote_node)
    @remote_node  = remote_node
    @actor_class  = actor_class
    @actor_name   = rand # TODO: replace with uuid?
    Actor[:manager] << T[:remote_create, @remote_node, @actor_name, @actor_class]
    receive_loop
  end
  
  def forward(message)
    @node_manager << T[:remote_send, @remote_node, @actor, message]
  end
  call :forward, :when => Object
end
