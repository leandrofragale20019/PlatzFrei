class CreateReservierungen < ActiveRecord::Migration[8.1]
  def change
    create_table :reservierungen do |t|
      t.references :benutzer, null: false, foreign_key: true
      t.references :zeitfenster, null: false, foreign_key: true, index: false
      t.string :status, null: false, default: "reserviert"
      t.datetime :erstellt_am, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
    # Höchstens eine aktive (nicht stornierte) Reservierung pro Zeitfenster.
    # Stornierte Reservierungen bleiben als Zeilen erhalten (Auditierung),
    # daher kein globaler Unique-Index auf zeitfenster_id.
    add_index :reservierungen, :zeitfenster_id, unique: true, where: "status = 'reserviert'", name: "index_reservierungen_on_aktive_zeitfenster"
  end
end
