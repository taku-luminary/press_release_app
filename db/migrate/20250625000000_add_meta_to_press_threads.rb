class AddMetaToPressThreads < ActiveRecord::Migration[7.1]
  def change
    add_column :press_threads, :meta, :json
  end
end 