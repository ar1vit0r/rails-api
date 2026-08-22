class HomeController < ApplicationController
  skip_before_action :authorize_request

  def index
    redirect_to "/api-docs", allow_other_host: true
  end
end
