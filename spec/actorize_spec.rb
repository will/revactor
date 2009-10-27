require File.dirname(__FILE__) + '/../lib/revactor'

describe "actorize" do
  class Dog
    extend Actorize
    def initialize(sitting=false)
      @sitting = sitting
      loop do
        Actor.receive do |filter|
          filter.when(:sit)         { @sitting = true }
          filter.when(T[:sitting?]) { |_,requester| requester << @sitting }
        end
      end
    end
  end
  
  it "should let you spawn an actor"  do
    expect { Dog.spawn }.to_not raise_error
  end
    
  it "should make a normal class an actor" do
    dog = Dog.spawn

    dog << T[:sitting?, Actor.current]
    response = Actor.receive { |f| f.when(Object) {|sitting| sitting} }
    response.should be_false
    
    dog << :sit

    dog << T[:sitting?, Actor.current]
    response = Actor.receive { |f| f.when(Object) {|sitting| sitting} }
    response.should be_true
  end
  
  it "should let you pass in arguments on initialization" do
    dog = Dog.spawn(true)

    dog << T[:sitting?, Actor.current]
    response = Actor.receive { |f| f.when(Object) {|sitting| sitting} }
    response.should be_true    
  end
end