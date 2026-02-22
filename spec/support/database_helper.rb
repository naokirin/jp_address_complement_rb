# frozen_string_literal: true

require 'active_record'
require 'sqlite3'

module DatabaseHelper
  def self.setup
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )
    create_table
  end

  def self.create_table
    ActiveRecord::Schema.define do
      create_table :jp_address_complement_postal_codes, force: true do |t|
        t.string :postal_code,     limit: 7,   null: false
        t.string :pref_code,       limit: 2,   null: false
        t.string :pref,            limit: 10,  null: false
        t.string :city,            limit: 50,  null: false
        t.string :town,            limit: 100
        t.string :kana_pref,       limit: 20
        t.string :kana_city,       limit: 100
        t.string :kana_town,       limit: 200
        t.boolean :has_alias,      default: false, null: false
        t.boolean :is_partial,     default: false, null: false
        t.boolean :is_large_office, default: false, null: false
        t.timestamps

        t.index :postal_code
        t.index %i[postal_code pref_code city town],
                unique: true,
                name: 'idx_jp_address_complement_unique'
      end
    end
  end

  def self.clean
    ActiveRecord::Base.connection.execute(
      'DELETE FROM jp_address_complement_postal_codes'
    )
  end
end
