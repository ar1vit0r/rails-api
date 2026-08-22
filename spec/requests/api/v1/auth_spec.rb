require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/register" do
    it "creates a new user" do
      post "/api/v1/register", params: { email: "new@example.com", password: "password123", password_confirmation: "password123" }
      expect(response).to have_http_status(:created)
    end

    it "returns errors for invalid data" do
      post "/api/v1/register", params: { email: "", password: "password123" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    it "returns a token" do
      post "/api/v1/login", params: { email: "test@example.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
    end

    it "returns unauthorized for invalid credentials" do
      post "/api/v1/login", params: { email: "test@example.com", password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
