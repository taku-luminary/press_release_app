class CreateGpts < ActiveRecord::Migration[7.1]
  def change
    create_table :gpts do |t|
      t.string :name
      t.text :prompt

      t.timestamps
    end
  end
end
