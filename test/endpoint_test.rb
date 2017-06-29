require 'test_helper'

class EndpointTest < Minitest::Spec
  Song = Struct.new(:id, :title, :length) do
    def self.find_by(id:nil); id.nil? ? nil : new(id) end
  end

  require 'representable/json'
  class Serializer < Representable::Decorator
    include Representable::JSON
    property :id
    property :title
    property :length

    class Errors < Representable::Decorator
      include Representable::JSON
      property :messages
    end
  end

  class Deserializer < Representable::Decorator
    include Representable::JSON
    property :title
  end

  class Show < Trailblazer::Operation
    extend Representer::DSL
    step Model( Song, :find_by )
    representer :serializer, Serializer
  end

  it 'uses the default handlers' do
    result = Show.({id: 1})
    endpoint_res = Trailblazer::Endpoint.new.(result)
    endpoint_res.must_equal '{"id":1}'
  end

  it 'overrides the handler' do
    result = Show.({id: 1})
    custom_handler = {
      success: {
        handler: ->(result) { 'I override' }
      }
    }
    endpoint_res = Trailblazer::Endpoint.new.(result, custom_handler)
    endpoint_res.must_equal 'I override'
  end
end
