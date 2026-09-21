class CreateBenutzer < ActiveRecord::Migration[8.1]
  def change
    create_table :benutzer do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :rolle, null: false, default: "mitglied"

      t.timestamps
    end
    add_index :benutzer, :email, unique: true
  end
end
