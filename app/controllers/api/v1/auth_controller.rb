module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authorize_request, only: %i[login register]

      def register
        user = User.new(register_params)
        user.role ||= "user"
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user_json(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user_json(user) }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def me
        render json: user_json(@current_user)
      end

      private

      def register_params
        params.permit(:email, :password, :password_confirmation)
      end

      def user_json(user)
        { id: user.id, email: user.email, role: user.role }
      end
    end
  end
end
