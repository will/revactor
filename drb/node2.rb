require 'node_manager'

manager = NodeManager.spawn(:node2)
manager << :init


manager << T[:remote_create, :node_1, :rover, "Dog"]
Actor.sleep 2
manager << T[:remote_send, :node_1, :rover, :sit]

loop { Actor.sleep 2 }