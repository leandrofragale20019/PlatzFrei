class CreateProtokolle < ActiveRecord::Migration[8.1]
  def change
    create_table :protokolle do |t|
      t.references :reservierung, null: false, foreign_key: true
      t.references :akteur, null: false, foreign_key: { to_table: :benutzer }
      t.string :aktion, null: false
      t.datetime :zeitpunkt, null: false

      t.timestamps
    end
  end
end
