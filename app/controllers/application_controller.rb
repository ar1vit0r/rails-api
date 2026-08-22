class ApplicationController < ActionController::API
  before_action :authorize_request

  private

  def authorize_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    decoded = JsonWebToken.decode(token)
    @current_user = User.find_by(id: decoded[:user_id]) if decoded
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def require_admin!
    render json: { error: "Forbidden" }, status: :forbidden unless @current_user&.admin?
  end
end
