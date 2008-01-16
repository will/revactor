#--
# Copyright (C)2007 Tony Arcieri
# You can redistribute this under the terms of the Ruby license
# See file LICENSE for details
#++

require File.dirname(__FILE__) + '/../revactor'

module Revactor
  # Revactor::Server wraps an Actor's receive loop and issues callbacks to
  # a class which implements Revactor::Behaviors::Server.  It eases the
  # creation of standard synchronous "blocking" calls by abstracting away 
  # inter-Actor communication and also providing baked-in state management.
  #
  # When used properly, Revactor::Server can implement transactional
  # semantics, ensuring only successful calls mutate the previous state
  # and erroneous/exception-raising ones do not.
  #
  # The design is modeled off Erlang/OTP's gen_server
  class Server
    # How long to wait for a response to a call before timing out
    # This value also borrowed from Erlang.  More cargo culting!
    DEFAULT_CALL_TIMEOUT = 5
    
    def initialize(obj, options = {}, *args)
      @obj = obj
      @actor = Actor.new(&method(:start).to_proc)
      
      Actor[options[:register]] = @actor if options[:register]
      
      @timeout = nil
      @state = obj.start(*args)
    end
    
    # Call the server with the given message
    def call(message, options = {})
      options[:timeout] ||= DEFAULT_CALL_TIMEOUT
      
      @actor << T[:call, Actor.current, message]
      Actor.receive do |filter|
        filter.when(Case[:call_reply, @actor, Object]) { |_, _, reply| reply }
        filter.when(Case[:call_error, @actor, Object]) { |_, _, ex| raise ex }
        filter.after(options[:timeout]) { raise 'timeout' }
      end
    end
    
    # Send a cast to the server
    def cast(message)
      @actor << T[:cast, message]
      message
    end
    
    def start
      @running = true
      while @running do
        Actor.receive do |filter|
          filter.when(Object) { |message| handle_message(message) }
          filter.after(@timeout) { stop(:timeout) } if @timeout
        end
      end
    end
    
    #########
    protected
    #########
    
    # Dispatch the incoming message to the appropriate handler
    def handle_message(message)
      case message.first
      when :call then handle_call(message)
      when :cast then handle_cast(message)
      else handle_info(message)
      end
    end
    
    # Wrapper for calling the provided object's handle_call method
    def handle_call(message)
      _, from, body = message
      
      begin
        result = @obj.handle_call(body, from, @state)
        case result.first
        when :reply
          _, reply, @state, @timeout = result
          from << T[:call_reply, Actor.current, reply]
        when :noreply
          _, @state, @timeout = result
        when :stop
          _, reason, @state = result
          stop(reason)
        end
      rescue Exception => ex
        log_exception(ex)
        from << T[:call_error, Actor.current, ex]
      end
    end
    
    # Wrapper for calling the provided object's handle_cast method
    def handle_cast(message)
      _, body = message
    
      begin
        result = @obj.handle_cast(body, @state)
        case result.first
        when :noreply
          _, @state, @timeout = result
        when :stop
          _, reason, @state = result
          stop(reason)
        end
      rescue Exception => e
        log_exception(e)
      end
    end
    
    # Wrapper for calling the provided object's handle_info method
    def handle_info(message)
      begin
        result = @obj.handle_info(message, @state)
        case result.first
        when :noreply
          _, @state, @timeout = result
        when :stop
          _, reason, @state = result
          stop(reason)
        end
      rescue Exception => e
        log_exception(e)
      end
    end
    
    # Stop the server
    def stop(reason)
      @running = false
      @obj.terminate(reason, @state)
    end
    
    # Log an exception
    # FIXME this should really go to a logger, not STDERR
    def log_exception(exception)
      STDERR.write "Rev::Server exception: #{exception}\n"
      STDERR.write exception.backtrace + "\n"
    end
  end
end