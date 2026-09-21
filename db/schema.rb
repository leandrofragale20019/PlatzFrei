# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_21_085540) do
  create_table "benutzer", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest"
    t.string "rolle", default: "mitglied", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_benutzer_on_email", unique: true
  end

  create_table "protokolle", force: :cascade do |t|
    t.integer "akteur_id", null: false
    t.string "aktion", null: false
    t.datetime "created_at", null: false
    t.integer "reservierung_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "zeitpunkt", null: false
    t.index ["akteur_id"], name: "index_protokolle_on_akteur_id"
    t.index ["reservierung_id"], name: "index_protokolle_on_reservierung_id"
  end

  create_table "reservierungen", force: :cascade do |t|
    t.integer "benutzer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "erstellt_am", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "status", default: "reserviert", null: false
    t.datetime "updated_at", null: false
    t.integer "zeitfenster_id", null: false
    t.index ["benutzer_id"], name: "index_reservierungen_on_benutzer_id"
    t.index ["zeitfenster_id"], name: "index_reservierungen_on_aktive_zeitfenster", unique: true, where: "status = 'reserviert'"
  end

  create_table "sportplaetze", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "sportart", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wartelisten", force: :cascade do |t|
    t.integer "benutzer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zeitfenster_id", null: false
    t.index ["benutzer_id"], name: "index_wartelisten_on_benutzer_id"
    t.index ["zeitfenster_id", "benutzer_id"], name: "index_wartelisten_on_zeitfenster_id_and_benutzer_id", unique: true
  end

  create_table "zeitfenster", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ende", null: false
    t.boolean "gesperrt", default: false, null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "sportplatz_id", null: false
    t.datetime "start", null: false
    t.datetime "updated_at", null: false
    t.index ["sportplatz_id"], name: "index_zeitfenster_on_sportplatz_id"
  end

  add_foreign_key "protokolle", "benutzer", column: "akteur_id"
  add_foreign_key "protokolle", "reservierungen"
  add_foreign_key "reservierungen", "benutzer"
  add_foreign_key "reservierungen", "zeitfenster"
  add_foreign_key "wartelisten", "benutzer"
  add_foreign_key "wartelisten", "zeitfenster"
  add_foreign_key "zeitfenster", "sportplaetze"
end
