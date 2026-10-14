module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        counts = @current_user.tasks.group(:category_id).count
        render json: Category.all.map { |c| { id: c.id, name: c.name, tasks_count: counts.fetch(c.id, 0) } }
      end

      def show
        category = Category.find(params[:id])
        tasks = @current_user.tasks.where(category: category)
        render json: { id: category.id, name: category.name, tasks: tasks.map { |t| task_json(t) } }
      end

      private

      def task_json(task)
        {
          id: task.id,
          title: task.title,
          status: task.status,
          priority: task.priority
        }
      end
    end
  end
end
