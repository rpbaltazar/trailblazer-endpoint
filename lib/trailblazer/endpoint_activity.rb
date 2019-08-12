module Trailblazer
  class EndpointActivity < Trailblazer::Activity::Path
    step :created, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :deleted, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :found, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :success, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :unauthenticated, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :not_found, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :invalid, Output(Activity::Right, :success) => Id(:render), Output(Activity::Left, :failure) => Track(:success)
    step :fallback, Output(Activity::Left, :failure) => Track(:success)
    step :render

    private

    def created(options, activity:, representer:, **)
      return false unless activity.success? && activity["model.action"] == :new

      options[:result] = { "data": representer.new(activity[:model]), "status": :created }
    end

    def deleted(options, activity:, **)
      return false unless activity.success? && activity["model.action"] == :destroy

      options[:result] = { "data": { id: activity[:model].id }, "status": :ok }
    end

    def found(options, activity:, representer:, **)
      return false unless activity.success? && activity["model.action"] == :find_by

      options[:result] = { "data": representer.new(activity[:model]), "status": :ok }
    end

    def success(options, activity:, **)
      return false unless activity.success?

      representer = options[:representer]
      data = if representer
               representer.new(activity[:model])
             else
               activity[:model]
             end

      options[:result] = { "data": data, "status": :ok }
    end

    def unauthenticated(options, activity:, **)
      return false unless activity.policy_error?

      options[:result] = { "data": {}, "status": :unauthorized }
    end

    def not_found(options, activity:, **)
      return false unless activity.failure? && activity["result.model"]&.failure?

      options[:result] = {
        "data": { errors: activity["result.model.errors"] },
        "status": :unprocessable_entity
      }
    end

    def invalid(options, activity:, **)
      return false unless activity.failure?

      options[:result] = {
        "data": { errors: activity.errors || activity[:errors] },
        "status": :unprocessable_entity
      }
    end

    def fallback(options, _activity:, **)
      options[:result] = {
        "data": { errors: "Can't process the result" },
        "status": :unprocessable_entity
      }
    end

    def render(options, **)
      # TODO: Think about the api for this endpoint
      # should this make use of the respond_to or just return and let the
      # controller make use of the result of this activity?
    end
  end
end
