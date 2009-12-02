require 'rinda/tuplespace'
DRb.start_service
module TupleClient
  def self.get_ts
    DRbObject.new(nil, 'druby://localhost:5000')
  end
end