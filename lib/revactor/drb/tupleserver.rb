require 'rinda/tuplespace'

module Revactor
  module TupleServer
    def selfstart_server
      ts = Rinda::TupleSpace.new
      DRb.start_service('druby://localhost:5000', ts)
      DRb.thread.join
    end
  end
end