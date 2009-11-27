require 'node_manager'

class Dog
  extend Actorize

  def initialize(sitting=false)
    @sitting = sitting
    receive_loop
  end

  def sit
    @sitting = true
    puts "SIT"
  end
  call :sit, :when => :sit

  def sitting?(_, sender)
    sender[:sender] << T[sender[:key], @sitting]
  end
  call :sitting?, :when => T[:sitting?]
end



manager = NodeManager.spawn(:node_1)
manager << :init

loop { Actor.sleep 2 }