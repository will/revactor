require 'rinda/tuplespace'
module Revactor
  module TupleClient
    def self.get_ts
      DRb.start_service
      DRbObject.new(nil, 'druby://localhost:5000')
    end
  end
end