require 'node_manager'

manager = NodeManager.spawn(:node2)
manager << :init

remote = RemoteActor.spawn("Dog", :node_1)
remote << :sit

loop { Actor.sleep 2 }