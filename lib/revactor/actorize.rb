#--
# Copyright (C)2007 Tony Arcieri
# You can redistribute this under the terms of the Ruby license
# See file LICENSE for details
#++

# Any class can be "actorized" by extending it with the Actorize module:
#
#  class MyClass
#    extend Actorize
#  end
#
# This will create MyClass.spawn and MyClass.spawn_link instance methods.
# Now you can create instances of your class which run inside Actors:
#
#  actor = MyClass.spawn
#
# Actorize defines method_missing for the Actor object, and will delegate
# any method calls to the Actor to MyClass's call method.  This method
# should be defined with the following signature:
#
#  class MyClass
#    extend Actorize
#    
#    def self.call(actor, meth, *args)
#      ...
#    end
#  end
#
# The call method receives the actor the call was made on, the method that
# was invoked, and the arguments that were passed.  You can then write a
# simple RPC mechanism to send a message to the actor and receive a response:
#  
#  actor << [:call, Actor.current, meth, *args]
#  Actor.receive do |filter|
#    filter.when(T[:call_reply, actor]) { |_, _, response| response }
#  end
# 
# Using this approach, you can mix the synchronous approach of Objects with
# the asynchronous approach of Actors, and effectively duck type Actors
# to Objects.
#
module Actorize
  def self.extended(klass)
    klass.send :include, InstanceMethods
  end

  def call(method, pattern)
    @filters ||= []
    @filters << {:method => method, :pattern => pattern[:when]}
  end
 
  def spawn(*args)
    _actorize Actor.spawn(*args, &method(:new))
  end
  
  def spawn_link(*args)
    _actorize Actor.spawn_link(*args, &method(:new))
  end
  
  def filters
    @filters
  end
  
  #######
  private
  #######
  
  def _actorize(actor)
    actor.instance_variable_set(:@_class, self)
    actor
  end

  module InstanceMethods
    def method_missing(*args, &block)
      return super unless @_class.respond_to?(:call)
      @_class.call(self, *args, &block)
    end
    
    def remote_class
      @_class
    end
    
    def inspect
      "#<#{self.class}(#{remote_class}):0x#{object_id.to_s(16)}>"
    end

    def receive_loop
      return false unless self.class.filters
      loop do
        Actor.receive do |f|
         self.class.filters.each do |rule|
           f.when(rule[:pattern]) do |message|
             meth = rule[:method]
             if self.method(meth).arity == 0
               self.send(meth)
             else
               self.send(meth, *message)
             end
           end
         end
       end
      end
    end
  end
end
