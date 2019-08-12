module Trailblazer
  # NOTE: Expects to receive the result of an operation and the representer
  # class as params in the ctx. This endpoint will then mutate the context
  # to add the represented data and the matched result that can be used for
  # render
  class EndpointActivity < Trailblazer::Activity::Railway
    # step :check_mandatory_params, Output(Activity::Left, :failure) => End(:missing_params)
    step :created, Output(Activity::Right, :success) => End(:render), Output(Activity::Left, :failure) => Track(:success)
    # step :deleted, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    # step :found, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    # step :success, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    # step :unauthenticated, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    # step :not_found, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    # step :invalid, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :fallback, Output(Activity::Right, :success) => End(:render)

    private

    def created((ctx, flow_options), *)
      activity = ctx[:activity]
      if activity.success? && activity["model.action"] == :new
        signal = Trailblazer::Activity::Right
        representer = ctx[:representer]
        ctx = ctx.merge(
          result: { data: representer.new(activity[:model]),
                    status: :created }
        )
      else
        signal = Trailblazer::Activity::Left
      end
      [signal, [ctx, flow_options]]
    end

    # def deleted(options, activity:, **)
    #   return false unless activity.success? && activity["model.action"] == :destroy

    #   options[:result] = { "data": { id: activity[:model].id }, "status": :ok }
    # end

    # def found(options, activity:, representer:, **)
    #   return false unless activity.success? && activity["model.action"] == :find_by

    #   options[:result] = { "data": representer.new(activity[:model]), "status": :ok }
    # end

    # def success(options, activity:, **)
    #   return false unless activity.success?

    #   representer = options[:representer]
    #   data = if representer
    #            representer.new(activity[:model])
    #          else
    #            activity[:model]
    #          end

    #   options[:result] = { "data": data, "status": :ok }
    # end

    # def unauthenticated(options, activity:, **)
    #   return false unless activity.policy_error?

    #   options[:result] = { "data": {}, "status": :unauthorized }
    # end

    # def not_found(options, activity:, **)
    #   return false unless activity.failure? && activity["result.model"]&.failure?

    #   options[:result] = {
    #     "data": { errors: activity["result.model.errors"] },
    #     "status": :unprocessable_entity
    #   }
    # end

    # def invalid(options, activity:, **)
    #   return false unless activity.failure?

    #   options[:result] = {
    #     "data": { errors: activity.errors || activity[:errors] },
    #     "status": :unprocessable_entity
    #   }
    # end

    def fallback((ctx, flow_options), *)
      signal = Trailblazer::Activity::Right
      ctx = ctx.merge(
        result: { "data": { errors: "Can't process the result" },
                  "status": :unprocessable_entity }
      )
      [signal, [ctx, flow_options]]
    end
  end
end
