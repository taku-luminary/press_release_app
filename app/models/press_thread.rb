class PressThread < ApplicationRecord
  has_many :messages, dependent: :destroy
  validates :title, presence: true
  attribute :meta, :json, default: {}
end
