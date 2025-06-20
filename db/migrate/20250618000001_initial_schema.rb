class InitialSchema < ActiveRecord::Migration[7.1]
  def change
    # Create press_threads table
    create_table :press_threads do |t|
      t.string :title
      t.timestamps
    end

    # Create messages table
    create_table :messages do |t|
      t.text :content
      t.references :press_thread, null: false, foreign_key: true
      t.string :role, default: 'user'
      t.timestamps
    end

    # Create gpts table
    create_table :gpts do |t|
      t.string :name
      t.text :prompt
      t.text :description
      t.text :instructions
      t.timestamps
    end
  end
end 