# frozen_string_literal: true

require 'spec_helper'
require 'generator_spec'
require 'generators/jp_address_complement/install_generator'

RSpec.describe JpAddressComplement::Generators::InstallGenerator do
  include GeneratorSpec::TestCase

  destination File.expand_path('../../../tmp/generators', __dir__)

  before { prepare_destination }

  describe 'the generated files' do
    before { run_generator }

    it 'マイグレーションファイルを生成する' do
      migration_files = Dir.glob(
        File.join(destination_root, 'db/migrate/*create_jp_address_complement_postal_codes.rb')
      )
      expect(migration_files.size).to eq(1)
    end

    it '生成されたファイルに CreateJpAddressComplementPostalCodes クラスが含まれる' do
      migration_file = Dir.glob(
        File.join(destination_root, 'db/migrate/*create_jp_address_complement_postal_codes.rb')
      ).first
      content = File.read(migration_file)
      expect(content).to include('CreateJpAddressComplementPostalCodes')
    end

    it '生成されたファイルに postal_code カラムが含まれる' do
      migration_file = Dir.glob(
        File.join(destination_root, 'db/migrate/*create_jp_address_complement_postal_codes.rb')
      ).first
      content = File.read(migration_file)
      expect(content).to include('postal_code')
    end
  end
end
