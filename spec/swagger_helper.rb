require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.to_s + "/swagger/v1"

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Rails API",
        version: "v1",
        description: "Task management API with JWT authentication"
      },
      paths: {},
      servers: [
        { url: "https://rails-api-zm3n.onrender.com", description: "Production" }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
