#--
# Copyright (C)2007 Tony Arcieri
# You can redistribute this under the terms of the Ruby license
# See file LICENSE for details
#++

class Actor
  # Actor mailbox.  For purposes of efficiency the mailbox also handles 
  # suspending and resuming an actor when no messages match its filter set.
  class Mailbox
    attr_accessor :timer
    attr_accessor :timed_out
    attr_accessor :timeout_action

    def initialize
      @timer = nil
      @queue = []
    end

    # Add a message to the mailbox queue
    def <<(message)
      @queue << message
    end

    # Attempt to receive a message
    def receive
      raise ArgumentError, "no filter block given" unless block_given?

      # Clear mailbox processing variables
      action = matched_index = nil
      at = 0
    
      # Clear timeout variables
      @timed_out = false
      @timeout_action = nil
    
      # Build the filter
      filter = Filter.new(self)
      yield filter
      raise ArgumentError, "empty filter" if filter.empty?

      # Process incoming messages
      while action.nil?
        at.upto(@queue.size - 1) do |i|
          next unless action = filter.match(@queue[i])
          matched_index = i
          break
        end
        
        at = @queue.size

        # Ignore timeouts if we've matched a message
        if action
          @timed_out = false
          break
        end
        
        # Otherwise run the timeout action
        action = @timeout_action if @timed_out

        # If no matching action is found, reschedule until we get another message
        Actor.reschedule unless action
      end

      @timeout_action = nil
      
      if @timer
        @timer.detach if @timer.attached?
        @timer = nil
      end
    
      # If we encountered a timeout, call the action directly
      if @timed_out
        @timed_out = false
        return action.call
      end
    
      # Otherwise we matched a message, so process it with the action      
      action.call @queue.delete_at(matched_index)
    end
    
    # Is the mailbox empty?
    def empty?
      @queue.empty?
    end
    
    # Clear the mailbox
    def clear
      @queue.clear
    end
  
    #######
    private
    #######
  
    # Timeout class, used to implement receive timeouts
    class Timer < Rev::TimerWatcher
      def initialize(seconds, actor)
        @actor = actor
        super(seconds)
      end

      def on_timer
        detach
        @actor.mailbox.timed_out = true
        @actor.scheduler << @actor
      end
    end

    # Mailbox filterset.  Takes patterns or procs to match messages with
    # and returns the associated proc when a pattern matches.
    class Filter
      def initialize(mailbox)
        @mailbox = mailbox
        @ruleset = []
      end

      # Provide a pattern to match against with === and a block to call
      # when the pattern is matched.
      def when(pattern, &action)
        # Don't explicitly require an action to be specified 
        action ||= proc {}
        @ruleset << [pattern, action]
      end

      # Provide a timeout (in seconds, can be a Float) to wait for matching
      # messages.  If the timeout elapses, the given block is called.
      def after(seconds, &action)
        raise ArgumentError, "timeout already specified" if @mailbox.timer
        raise ArgumentError, "must be zero or positive" if seconds < 0
      
        # Don't explicitly require an action to be specified
        @mailbox.timeout_action = action || proc {}
        @mailbox.timer = Timer.new(seconds, Actor.current).attach(Rev::Loop.default)
      end

      # Match a message using the filter
      def match(message)
        _, action = @ruleset.find { |pattern, _| pattern === message }
        action
      end

      # Is the filterset empty?
      def empty?
        @ruleset.empty? and not @mailbox.timer
      end
    end
  end
end