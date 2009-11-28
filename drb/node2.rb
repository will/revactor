require 'node_manager'

manager = NodeManager.spawn(:node2)
manager << :init

p Actor.class_variable_get(:@@registered)
Actor[:manager] << T[:remote_create, :node_1, :rover, "Dog"]
Actor.sleep 2 # need to get proxy actors to hold messages until
              # remote actor is up, so we don't need to sleep
Actor[:manager] << T[:remote_send, :node_1, :rover, :sit]

loop { Actor.sleep 2 }