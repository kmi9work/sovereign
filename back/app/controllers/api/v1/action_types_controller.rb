module Api
  module V1
    class ActionTypesController < BaseController
      before_action :set_action_type, only: %i[show update destroy with_lists]

      def index
        @action_types = ActionType.all.order(:name)
        render json: @action_types
      end

      def show
        render json: @action_type
      end

      def create
        @action_type = ActionType.new(action_type_params)
        if @action_type.save
          render json: @action_type, status: :created
        else
          render json: { errors: @action_type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @action_type.update(action_type_params)
          render json: @action_type
        else
          render json: { errors: @action_type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @action_type.destroy
        head :no_content
      end

      # GET /api/v1/action_types/:id/with_lists?country_id=X
      def with_lists
        country = Country.find(params[:country_id])

        other_countries = Country.where.not(id: country.id).order(:name)

        provinces_of_country = country.provinces.order(:name)

        provinces_of_other = Province.where.not(country_id: country.id)
                                     .includes(:country)
                                     .order(:name)

        render json: {
          action_type: @action_type,
          other_countries: other_countries.as_json(only: %i[id name]),
          provinces_of_country: provinces_of_country.as_json(only: %i[id name], methods: [:country_name]),
          provinces_of_other: provinces_of_other.as_json(only: %i[id name], methods: [:country_name])
        }
      end

      private

      def set_action_type
        @action_type = ActionType.find(params[:id])
      end

      def action_type_params
        params.require(:action_type).permit(:action_type, :name, :display_params, :success_result, :failure_result)
      end
    end
  end
end
