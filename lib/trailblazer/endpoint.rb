module Trailblazer
  class Matcher
    def initialize(cases)
      @cases = cases
    end

    def call(result)
      @cases.each do |key, value|
        if value[:match].(result)
          return value[:handler].(result)
        end
      end
    end
  end

  class Endpoint
    Matcher = Matcher.new({
      success: {
        match: ->(result) { result.success? },
        handler: ->(result) { result["representer.serializer.class"].new(result["model"]).to_json }
      }
    })

    # `call`s the operation.
    def self.call(operation_class, handlers, *args, &block)
      result = operation_class.(*args)
      new.(result, handlers, &block)
    end

    def call(result, handlers=nil, &block)
      matcher.(result, &block) and return if block_given? # evaluate user blocks first.
      matcher.(result)     # then, generic Rails handlers in controller context.
    end

    def matcher
      Matcher
    end
  end
end
