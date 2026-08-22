require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "GET /api/v1/tasks" do
    it "returns user's tasks" do
      create_list(:task, 3, user: user, category: category)
      get "/api/v1/tasks", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end

  describe "POST /api/v1/tasks" do
    it "creates a task" do
      expect {
        post "/api/v1/tasks", params: { title: "New task", status: "todo", priority: 1, category_id: category.id }, headers: headers
      }.to change(Task, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "deletes a task" do
      task = create(:task, user: user, category: category)
      expect {
        delete "/api/v1/tasks/#{task.id}", headers: headers
      }.to change(Task, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
