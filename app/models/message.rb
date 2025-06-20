class Message < ApplicationRecord
  belongs_to :press_thread
  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
end
