# frozen_string_literal: true

require 'active_record'
require 'sqlite3'

module DatabaseHelper
  def self.setup
    ActiveRecord::Base.establish_connection(connection_config)
    create_table
  end

  def self.connection_config
    adapter = ENV.fetch('DB_ADAPTER', 'sqlite3')

    if adapter == 'sqlite3'
      sqlite_config
    else
      relational_config(adapter)
    end
  end

  def self.sqlite_config
    {
      adapter: 'sqlite3',
      database: ENV.fetch('DB_DATABASE', ':memory:')
    }
  end

  def self.relational_config(adapter)
    config = {
      adapter: adapter,
      database: ENV.fetch('DB_DATABASE', 'jp_address_complement_test'),
      host: ENV.fetch('DB_HOST', '127.0.0.1')
    }

    config[:port] = ENV['DB_PORT'] if ENV['DB_PORT']
    config[:username] = ENV['DB_USERNAME'] if ENV['DB_USERNAME']
    config[:password] = ENV['DB_PASSWORD'] if ENV['DB_PASSWORD']

    config
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
