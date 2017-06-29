require 'test_helper'
require 'json'

class EndpointTest < Minitest::Spec
  Song = Struct.new(:id, :title, :length) do
    def self.find_by(id:nil); id.nil? ? nil : new(id, "fancy_stuff") end
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
    endpoint_res.must_equal '{"id":1,"title":"fancy_stuff"}'
  end

  it 'overrides the handler' do
    result = Show.({id: 1})
    custom_handlers = [{
      success: {
        handler: ->(result) { 'I override' }
      }
    }]
    endpoint_res = Trailblazer::Endpoint.new.(result, custom_handlers)
    endpoint_res.must_equal 'I override'
  end

  it 'apends cases && overrides matchers' do
    result = Show.({id: 1})
    custom_handlers = [{
      success: {
        match: ->(result) { result.failure? }
      },
      fancy_stuff: {
        match: ->(result) { result.success? },
        handler: ->(result) { { "fancy_stuff": 1 }.to_json }
      }
    }]
    endpoint_res = Trailblazer::Endpoint.new.(result, custom_handlers)
    endpoint_res.must_equal '{"fancy_stuff":1}'
  end
end
