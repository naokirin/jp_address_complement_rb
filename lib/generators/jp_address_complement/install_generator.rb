# frozen_string_literal: true
# rbs_inline: enabled

require 'rails/generators'
require 'rails/generators/migration'

module JpAddressComplement
  module Generators
    # `rails g jp_address_complement:install` で呼び出されるジェネレーター
    # 住所テーブル用マイグレーションファイルを利用者アプリの db/migrate/ に生成する
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      # __dir__ は String を返す（Rails の RBS で nil と誤推論される場合の対策）
      source_root File.expand_path('templates', __dir__.to_s)
      desc 'Creates a migration file for jp_address_complement postal codes table'

      # Rails::Generators::Base の RBS に next_migration_number 等が未定義のため steep:ignore
      # @rbs (String dirname) -> String
      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1 # steep:ignore
        ActiveRecord::Migration.next_migration_number(next_migration_number) # steep:ignore
      end

      # @rbs () -> void
      def create_migration_file
        migration_template( # steep:ignore
          'create_jp_address_complement_postal_codes.rb.erb',
          'db/migrate/create_jp_address_complement_postal_codes.rb'
        )
      end
    end
  end
end
