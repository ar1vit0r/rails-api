module Api
  module V1
    class TasksController < ApplicationController
      before_action :set_task, only: %i[show update destroy]

      def index
        tasks = @current_user.tasks.includes(:category)
        tasks = tasks.by_status(params[:status]) if params[:status].present?
        tasks = tasks.by_priority(params[:priority]) if params[:priority].present?
        tasks = tasks.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
        render json: tasks.map { |t| task_json(t) }
      end

      def show
        render json: task_json(@task)
      end

      def create
        task = @current_user.tasks.build(task_params)
        if task.save
          render json: task_json(task), status: :created
        else
          render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @task.update(task_params)
          render json: task_json(@task)
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_task
        @task = @current_user.tasks.find(params[:id])
      end

      def task_params
        params.permit(:title, :description, :status, :priority, :category_id)
      end

      def task_json(task)
        {
          id: task.id,
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          category: task.category.name,
          created_at: task.created_at,
          updated_at: task.updated_at
        }
      end
    end
  end
end
