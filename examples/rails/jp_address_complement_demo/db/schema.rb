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

ActiveRecord::Schema[8.1].define(version: 2026_02_28_083709) do
  create_table "jp_address_complement_postal_codes", force: :cascade do |t|
    t.string "city", limit: 50, null: false
    t.datetime "created_at", null: false
    t.boolean "has_alias", default: false, null: false
    t.boolean "is_large_office", default: false, null: false
    t.boolean "is_partial", default: false, null: false
    t.string "kana_city", limit: 100
    t.string "kana_pref", limit: 20
    t.string "kana_town", limit: 200
    t.string "postal_code", limit: 7, null: false
    t.string "pref", limit: 10, null: false
    t.string "pref_code", limit: 2, null: false
    t.string "town", limit: 100
    t.datetime "updated_at", null: false
    t.integer "version", default: 0, null: false
    t.index "postal_code, pref_code, city, COALESCE(town,''), COALESCE(kana_pref,''), COALESCE(kana_city,''), COALESCE(kana_town,'')", name: "idx_jp_address_complement_unique", unique: true
    t.index ["postal_code"], name: "idx_jp_address_complement_postal_code"
    t.index ["version"], name: "idx_jp_address_complement_version"
  end
end
