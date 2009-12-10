require 'rinda/tuplespace'

module Revactor
  module TupleServer
    def self.start_server(uri = 'druby://localhost:5000')
      ts = Rinda::TupleSpace.new
      DRb.start_service(uri, ts)
      DRb.thread.join
    end
  end
end