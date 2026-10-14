require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:category) { create(:category) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "GET /api/v1/categories/:id" do
    it "returns only the current user's tasks in the category" do
      mine = create(:task, user: user, category: category)
      create(:task, user: other_user, category: category)

      get "/api/v1/categories/#{category.id}", headers: headers

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["tasks"].map { |t| t["id"] }
      expect(ids).to eq([ mine.id ])
    end

    it "does not expose other users' emails or titles" do
      create(:task, user: user, category: category)
      create(:task, user: other_user, category: category, title: "private-title")

      get "/api/v1/categories/#{category.id}", headers: headers

      expect(response.body).not_to include(other_user.email)
      expect(response.body).not_to include("private-title")
    end
  end
end
