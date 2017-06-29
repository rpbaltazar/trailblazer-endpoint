module Trailblazer
  class Matcher
    def initialize(cases)
      @cases = cases
    end

    def call(result, custom_handlers)
      merge_cases(custom_handlers) if custom_handlers

      @cases.each do |key, value|
        if value[:match].(result)
          return value[:handler].(result)
        end
      end
    end

    private

    def merge_cases(custom_handlers)
      custom_handlers.each do |handler|
        handler.each_pair do |current_key, other_value|
          if @cases[current_key]
            @cases[current_key][:match] = other_value[:match] if other_value[:match].is_a?(Proc)
            @cases[current_key][:handler] = other_value[:handler] if other_value[:handler].is_a?(Proc)
          else
            return unless other_value[:match].is_a?(Proc) && other_value[:handler].is_a?(Proc)
            @cases[current_key] = other_value
          end
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
      matcher.(result, handlers)     # then, generic Rails handlers in controller context.
    end

    def matcher
      Matcher
    end
  end
end
