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
        DatabaseHelper.jp_address_columns(t)
        DatabaseHelper.jp_address_indexes(t)
      end
    end
  end

  def self.jp_address_columns(table)
    table.string :postal_code,     limit: 7,   null: false
    table.string :pref_code,       limit: 2,   null: false
    table.string :pref,            limit: 10,  null: false
    table.string :city,            limit: 50,  null: false
    table.string :town,            limit: 100
    table.string :kana_pref,       limit: 20
    table.string :kana_city,       limit: 100
    table.string :kana_town,       limit: 200
    table.boolean :has_alias,      default: false, null: false
    table.boolean :is_partial,     default: false, null: false
    table.boolean :is_large_office, default: false, null: false
    table.integer :version, default: 0, null: false
    table.timestamps
  end

  def self.jp_address_indexes(table)
    table.index :postal_code
    table.index %i[postal_code pref_code city town],
                unique: true,
                name: 'idx_jp_address_complement_unique'
    table.index :version, name: 'idx_jp_address_complement_version'
  end

  def self.clean
    ActiveRecord::Base.connection.execute(
      'DELETE FROM jp_address_complement_postal_codes'
    )
  end
end
