# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module JpAddressComplement
  module Generators
    # `rails g jp_address_complement:install` で呼び出されるジェネレーター
    # 住所テーブル用マイグレーションファイルを利用者アプリの db/migrate/ に生成する
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)
      desc 'Creates a migration file for jp_address_complement postal codes table'

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration_file
        migration_template(
          'create_jp_address_complement_postal_codes.rb.erb',
          'db/migrate/create_jp_address_complement_postal_codes.rb'
        )
      end
    end
  end
end
