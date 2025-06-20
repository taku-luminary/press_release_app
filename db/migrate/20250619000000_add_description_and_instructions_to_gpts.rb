class AddDescriptionAndInstructionsToGpts < ActiveRecord::Migration[7.1]
  def change
    add_column :gpts, :description, :text
    add_column :gpts, :instructions, :text
  end
end 