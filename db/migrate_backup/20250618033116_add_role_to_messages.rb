class AddRoleToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :role, :string, default: 'user'
    remove_column :messages, :is_ai, :boolean
  end
end 