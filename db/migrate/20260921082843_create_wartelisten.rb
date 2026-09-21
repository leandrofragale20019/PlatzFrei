class CreateWartelisten < ActiveRecord::Migration[8.1]
  def change
    create_table :wartelisten do |t|
      t.references :zeitfenster, null: false, foreign_key: true, index: false
      t.references :benutzer, null: false, foreign_key: true

      t.timestamps
    end
    add_index :wartelisten, [ :zeitfenster_id, :benutzer_id ], unique: true
  end
end
