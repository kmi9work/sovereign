module Api
  module V1
    class ActionsController < BaseController
      before_action :set_action, only: %i[show destroy mark_read]

      ACTION_INCLUDES = {
        position: { only: %i[id name] },
        action_type: { only: %i[id action_type name display_params success_result failure_result] },
        country: { only: %i[id name] },
        second_country: { only: %i[id name] },
        province: { only: %i[id name] }
      }.freeze

      def index
        @actions = Action.includes(:position, :action_type, :country, :second_country, :province)
                         .order(created_at: :desc)
        render json: @actions.as_json(include: ACTION_INCLUDES)
      end

      def show
        render json: @action.as_json(include: ACTION_INCLUDES)
      end

      # GET /api/v1/countries/:country_id/actions/current_cycle
      def current_cycle
        current_cycle = Parameter.first&.current_cycle || 1
        position_ids = Country.find(params[:country_id]).positions.pluck(:id)
        @actions = Action.includes(:position, :action_type, :province, :second_country)
                         .where(position_id: position_ids, cycle_number: current_cycle)
                         .order(created_at: :desc)
        render json: @actions.as_json(include: ACTION_INCLUDES)
      end

      # POST /api/v1/actions/perform
      def perform
        action_type = ActionType.find(params[:action_type_id])
        current_cycle = Parameter.first&.current_cycle || 1

        action_params = {
          position_id: params[:position_id],
          action_type_id: action_type.id,
          cycle_number: current_cycle,
          result: params.fetch(:result, true)
        }

        case action_type.display_params
        when "C"
          action_params[:country_id] = params[:country_id]
        when "P", "PF"
          action_params[:province_id] = params[:province_id]
          action_params[:country_id] = Province.find(params[:province_id]).country_id
        when "C2"
          action_params[:country_id] = params[:country_id]
          action_params[:second_country_id] = params[:second_country_id]
        end

        @action = Action.new(action_params)

        if @action.save
          broadcast_action("action_created")
          render json: @action.as_json(include: ACTION_INCLUDES), status: :created
        else
          render json: { errors: @action.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/actions/:id/mark_read
      def mark_read
        if @action.read
          render json: { error: "Action already marked as read" }, status: :unprocessable_entity
        elsif @action.update(read: true)
          broadcast_action("action_updated")
          render json: @action.as_json(include: ACTION_INCLUDES)
        else
          render json: { errors: @action.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @action.destroy
        head :no_content
      end

      private

      def set_action
        @action = Action.find(params[:id])
      end

      def broadcast_action(type)
        ActionCable.server.broadcast("actions_#{@action.position.country_id}", {
          type: type,
          action: @action.as_json(include: ACTION_INCLUDES)
        })
      end
    end
  end
end
