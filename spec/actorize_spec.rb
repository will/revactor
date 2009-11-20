require File.dirname(__FILE__) + '/../lib/revactor'

describe "actorize" do
  class Dog
    extend Actorize
    def initialize(sitting=false)
      @sitting = sitting
      loop do
        Actor.receive do |filter|
          filter.when(:sit)         { @sitting = true }
          filter.when(T[:sitting?]) do |_,sender|
            if Actor === sender
              sender << @sitting # async request
            else
              sender[:sender] << T[sender[:key], @sitting] # sync request
            end
          end
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
  
  describe "synchronous" do
    it "should be able to send synchronous messages" do
      dog = Dog.spawn
      ( dog >> T[:sitting?] ).should be_false
      dog << :sit
      ( dog >> T[:sitting?] ).should be_true    
    end

    it "it should catch the correct message, and not the first it gets" do
      dog = Dog.spawn

      Actor.current << true
      ( dog >> T[:sitting?] ).should be_false
    end
  end
end

describe "declaritive filters" do
   class Dog
    extend Actorize

    def initialize(sitting=false)
      @sitting = sitting
      receive_loop
    end

    def sit
      @sitting = true
    end
    call :sit, :when => :sit

    def sitting?(_, sender)
      sender[:sender] << T[sender[:key], @sitting]
    end
    call :sitting?, :when => T[:sitting?]
  end
 

  it "should work like the explicit case" do
    dog = Dog.spawn
    ( dog >> T[:sitting?] ).should be_false
    dog << :sit
    ( dog >> T[:sitting?] ).should be_true    
  end
end
