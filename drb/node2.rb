require 'node_manager'

manager = NodeManager.spawn(:node2)
manager << :init

# Actor[:manager] << T[:remote_create, :node_1, :rover, "Dog"]
remote = RemoteActor.spawn("Dog", :node_1)
Actor.sleep 10 # need to get proxy actors to hold messages until
              # remote actor is up, so we don't need to sleep
# Actor[:manager] << T[:remote_send, :node_1, :rover, :sit]
remote << :sit

loop { Actor.sleep 2 }