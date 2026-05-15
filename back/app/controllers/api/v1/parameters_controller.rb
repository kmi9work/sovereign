module Api
  module V1
    class ParametersController < BaseController
      def index
        @parameter = Parameter.first
        render json: @parameter
      end

      def show
        @parameter = Parameter.find(params[:id])
        render json: @parameter
      end

      def update
        @parameter = Parameter.find(params[:id])
        if @parameter.update(parameter_params)
          render json: @parameter
        else
          render json: { errors: @parameter.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/parameters/next_cycle
      def next_cycle
        @parameter = Parameter.first
        if @parameter
          @parameter.increment!(:current_cycle)
          broadcast_cycle
          render json: @parameter
        else
          render json: { error: "Parameter not found" }, status: :not_found
        end
      end

      # POST /api/v1/parameters/prev_cycle
      def prev_cycle
        @parameter = Parameter.first
        if @parameter
          @parameter.decrement!(:current_cycle)
          broadcast_cycle
          render json: @parameter
        else
          render json: { error: "Parameter not found" }, status: :not_found
        end
      end

      private

      def broadcast_cycle
        ActionCable.server.broadcast("cycle_global", {
          type: "cycle_update",
          current_cycle: @parameter.current_cycle
        })
      end

      def parameter_params
        params.require(:parameter).permit(:current_cycle)
      end
    end
  end
end
