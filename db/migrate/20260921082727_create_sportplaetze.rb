class CreateSportplaetze < ActiveRecord::Migration[8.1]
  def change
    create_table :sportplaetze do |t|
      t.string :name, null: false
      t.string :sportart, null: false

      t.timestamps
    end
  end
end
