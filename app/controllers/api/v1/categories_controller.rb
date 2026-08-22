module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        categories = Category.all
        render json: categories.map { |c| { id: c.id, name: c.name, tasks_count: c.tasks.count } }
      end

      def show
        category = Category.find(params[:id])
        render json: { id: category.id, name: category.name, tasks: category.tasks.map { |t| task_json(t) } }
      end

      private

      def task_json(task)
        {
          id: task.id,
          title: task.title,
          status: task.status,
          priority: task.priority,
          user: task.user.email
        }
      end
    end
  end
end
