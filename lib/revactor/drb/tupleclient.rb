require 'rinda/tuplespace'

module Revactor
  module TupleClient
    def self.get_ts(uri = 'druby://localhost:5000')
      DRb.start_service
      DRbObject.new(nil, uri)
    end
  end
end