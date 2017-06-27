require "dry/matcher"

module Trailblazer
  module Matcher
    class Case
      def initialize(match:, handler:)
        @match = match
        @handler = handler
      end
    end
  end

  class Endpoint
    Matcher = Dry::Matcher.new(
      present: Trailblazer::Matcher::Case.new(
        match:   ->(result) { result.success? && result["present"] },
        handler: ->(result) { puts result }
      ),
      success: Trailblazer::Matcher::Case.new(
        match:   ->(result) { result.success? },
        handler: ->(result) { puts result }
      ),
      created: Trailblazer::Matcher::Case.new(
        match:   ->(result) { result.success? && result["model.action"] == :new }, # the "model.action" doesn't mean you need Model.
        handler: ->(result) { puts result }
      ),
      not_found: Trailblazer::Matcher::Case.new(
        match:   ->(result) { result.failure? && result["result.model"] && result["result.model"].failure? },
        handler: ->(result) { puts result }
      ),
      unauthenticated: Trailblazer::Matcher::Case.new(
        match:   ->(result) { result.failure? && result["result.policy.default"].failure? }, # FIXME: we might need a &. here ;)
        handler: ->(result) { puts result }
      ),
      invalid: Trailblazer::Matcher::Case.new(
        match:   ->(result) { result.failure? && result["result.contract.default"] && result["result.contract.default"].failure? },
        handler: ->(result) { puts result }
      ),
    )

    def self.call(operation_class, handlers, *args, &block)
      # `call`s the operation.
      result = operation_class.(*args)
      # new endpoint instance with result, handlers and potential block
      new.(result, handlers, &block)
    end

    def call(result, handlers=nil, &block)
      matcher.(result, &block) and return if block_given? # evaluate user blocks first.
      matcher.(result, &handlers)     # then, generic Rails handlers in controller context.
    end

    def matcher
      Matcher
    end

    module Controller
      # endpoint(Create) do |m|
      #   m.not_found { |result| .. }
      # end
      def endpoint(operation_class, options={}, &block)
        handlers = Handlers::Rails.new(self, options).()
        Endpoint.(operation_class, handlers, *options[:args], &block)
      end
    end
  end
end
