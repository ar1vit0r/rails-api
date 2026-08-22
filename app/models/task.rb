class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[todo in_progress done] }
  validates :priority, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
end
