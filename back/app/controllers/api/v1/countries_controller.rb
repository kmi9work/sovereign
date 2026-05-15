module Api
  module V1
    class CountriesController < BaseController
      before_action :set_country, only: %i[show update destroy]

      def index
        @countries = Country.all.order(:name)
        render json: @countries
      end

      def with_positions
        @countries = Country.joins(:positions).distinct.order(:name)
        render json: @countries
      end

      def show
        render json: @country
      end

      def create
        @country = Country.new(country_params)
        if @country.save
          render json: @country, status: :created
        else
          render json: { errors: @country.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @country.update(country_params)
          render json: @country
        else
          render json: { errors: @country.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @country.destroy
        head :no_content
      end

      private

      def set_country
        @country = Country.find(params[:id])
      end

      def country_params
        params.require(:country).permit(:name)
      end
    end
  end
end
