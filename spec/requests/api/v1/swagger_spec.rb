require "swagger_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  path "/api/v1/register" do
    post "Register a new user" do
      tags "Auth"
      consumes "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string },
          password_confirmation: { type: :string }
        },
        required: %w[email password password_confirmation]
      }

      response "201", "registered" do
        let(:body) { { email: "swagger-register@example.com", password: "password123", password_confirmation: "password123" } }

        schema type: :object, properties: {
          token: { type: :string },
          user: { type: :object, properties: {
            id: { type: :integer },
            email: { type: :string },
            role: { type: :string }
          } }
        }
        run_test!
      end

      response "422", "invalid" do
        let(:body) { { email: "", password: "", password_confirmation: "" } }

        run_test!
      end
    end
  end

  path "/api/v1/login" do
    post "Login" do
      tags "Auth"
      consumes "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: %w[email password]
      }

      let(:user) { create(:user, password: "password123") }

      response "200", "logged in" do
        let(:body) { { email: user.email, password: "password123" } }

        schema type: :object, properties: {
          token: { type: :string },
          user: { type: :object, properties: {
            id: { type: :integer },
            email: { type: :string },
            role: { type: :string }
          } }
        }
        run_test!
      end

      response "401", "unauthorized" do
        let(:body) { { email: user.email, password: "wrongpassword" } }

        run_test!
      end
    end
  end
end

RSpec.describe "Api::V1::Tasks", type: :request do
  path "/api/v1/tasks" do
    let(:user) { create(:user) }
    let(:category) { create(:category) }
    let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }

    get "List tasks" do
      tags "Tasks"
      security [ Bearer: [] ]
      parameter name: :status, in: :query, type: :string, required: false
      parameter name: :priority, in: :query, type: :integer, required: false
      parameter name: :q, in: :query, type: :string, required: false

      response "200", "tasks listed" do
        let!(:task) { create(:task, user: user, category: category) }

        schema type: :array, items: {
          type: :object, properties: {
            id: { type: :integer },
            title: { type: :string },
            description: { type: :string },
            status: { type: :string },
            priority: { type: :integer },
            category: { type: :string },
            created_at: { type: :string },
            updated_at: { type: :string }
          }
        }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        run_test!
      end
    end

    post "Create a task" do
      tags "Tasks"
      security [ Bearer: [] ]
      consumes "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          description: { type: :string },
          status: { type: :string },
          priority: { type: :integer },
          category_id: { type: :integer }
        },
        required: %w[title status priority category_id]
      }

      response "201", "created" do
        let(:body) { { title: "New task", status: "todo", priority: 1, category_id: category.id } }

        run_test!
      end

      response "422", "invalid" do
        let(:body) { { title: "", status: "", priority: nil, category_id: category.id } }

        run_test!
      end
    end
  end

  path "/api/v1/tasks/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    let(:user) { create(:user) }
    let(:category) { create(:category) }
    let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
    let!(:task) { create(:task, user: user, category: category) }
    let(:id) { task.id }

    get "Get a task" do
      tags "Tasks"
      security [ Bearer: [] ]

      response "200", "task found" do
        schema type: :object, properties: {
          id: { type: :integer },
          title: { type: :string },
          description: { type: :string },
          status: { type: :string },
          priority: { type: :integer },
          category: { type: :string },
          created_at: { type: :string },
          updated_at: { type: :string }
        }
        run_test!
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test!
      end
    end

    put "Update a task" do
      tags "Tasks"
      security [ Bearer: [] ]
      consumes "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          status: { type: :string },
          priority: { type: :integer }
        }
      }

      response "200", "updated" do
        let(:body) { { title: "Updated title" } }

        run_test!
      end
    end

    delete "Delete a task" do
      tags "Tasks"
      security [ Bearer: [] ]

      response "204", "deleted" do
        run_test!
      end
    end
  end
end

RSpec.describe "Api::V1::Categories", type: :request do
  path "/api/v1/categories" do
    let(:user) { create(:user) }
    let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }

    get "List categories" do
      tags "Categories"
      security [ Bearer: [] ]

      response "200", "categories listed" do
        let!(:category) { create(:category) }

        schema type: :array, items: {
          type: :object, properties: {
            id: { type: :integer },
            name: { type: :string },
            tasks_count: { type: :integer }
          }
        }
        run_test!
      end
    end
  end
end
