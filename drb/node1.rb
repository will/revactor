require 'node_manager'

manager = NodeManager.spawn(:node_1)
manager << :init

loop { Actor.sleep 2 }