class CreateZeitfenster < ActiveRecord::Migration[8.1]
  def change
    create_table :zeitfenster do |t|
      t.references :sportplatz, null: false, foreign_key: true
      t.datetime :start, null: false
      t.datetime :ende, null: false
      t.integer :lock_version, null: false, default: 0
      t.boolean :gesperrt, null: false, default: false

      t.timestamps
    end
  end
end
