# frozen_string_literal: true

class CreateJpAddressComplementPostalCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :jp_address_complement_postal_codes do |t|
      t.string :postal_code,      limit: 7,   null: false
      t.string :pref_code,        limit: 2,   null: false
      t.string :pref,             limit: 10,  null: false
      t.string :city,             limit: 50,  null: false
      t.string :town,             limit: 100
      t.string :kana_pref,        limit: 20
      t.string :kana_city,        limit: 100
      t.string :kana_town,        limit: 200
      t.boolean :has_alias,       default: false, null: false
      t.boolean :is_partial,      default: false, null: false
      t.boolean :is_large_office, default: false, null: false
      t.integer :version, default: 0, null: false
      t.timestamps
    end

    add_index :jp_address_complement_postal_codes, :postal_code,
              name: 'idx_jp_address_complement_postal_code'

    add_index :jp_address_complement_postal_codes,
              %i[postal_code pref_code city town],
              unique: true,
              name: 'idx_jp_address_complement_unique'

    add_index :jp_address_complement_postal_codes, :version,
              name: 'idx_jp_address_complement_version'
  end
end
