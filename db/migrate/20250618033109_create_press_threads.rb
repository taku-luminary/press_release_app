class CreatePressThreads < ActiveRecord::Migration[7.1]
  def change
    create_table :press_threads do |t|
      t.string :title

      t.timestamps
    end
  end
end
