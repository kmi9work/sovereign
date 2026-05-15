module Api
  module V1
    class PositionsController < BaseController
      before_action :set_position, only: %i[show update destroy]

      def index
        if params[:country_id]
          current_cycle = Parameter.first&.current_cycle || 1
          @positions = Position.where(country_id: params[:country_id])
                               .includes(:action_types)
                               .order(:name)

          render json: @positions.map { |p|
            p.as_json(
              include: {
                action_types: { only: %i[id action_type name display_params success_result failure_result] }
              }
            ).merge(
              action_type_counts: p.actions.joins(:action_type)
                                    .where(cycle_number: current_cycle)
                                    .group('action_types.action_type')
                                    .count
            )
          }
        else
          @positions = Position.all.order(:name)
          render json: @positions
        end
      end

      def show
        render json: @position
      end

      def create
        @position = Position.new(position_params)
        if @position.save
          render json: @position, status: :created
        else
          render json: { errors: @position.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @position.update(position_params)
          render json: @position
        else
          render json: { errors: @position.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @position.destroy
        head :no_content
      end

      private

      def set_position
        @position = Position.find(params[:id])
      end

      def position_params
        params.require(:position).permit(:name, :country_id)
      end
    end
  end
end
