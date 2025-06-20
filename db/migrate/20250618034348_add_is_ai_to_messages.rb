class AddIsAiToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :is_ai, :boolean
  end
end
