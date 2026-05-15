module Api
  module V1
    class ProvincesController < BaseController
      before_action :set_province, only: %i[show update destroy]

      def index
        @provinces = Province.all.order(:name)
        render json: @provinces
      end

      def show
        render json: @province
      end

      def create
        @province = Province.new(province_params)
        if @province.save
          render json: @province, status: :created
        else
          render json: { errors: @province.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @province.update(province_params)
          render json: @province
        else
          render json: { errors: @province.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @province.destroy
        head :no_content
      end

      private

      def set_province
        @province = Province.find(params[:id])
      end

      def province_params
        params.require(:province).permit(:name, :country_id)
      end
    end
  end
end
