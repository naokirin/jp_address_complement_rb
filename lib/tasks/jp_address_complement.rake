# frozen_string_literal: true

require 'jp_address_complement'
require 'jp_address_complement/importers/csv_importer'

namespace :jp_address_complement do
  desc 'KEN_ALL.CSV から住所データをインポートする（CSV=<ファイルパス> または DOWNLOAD=1 で公式URLから取得）'
  task import: :environment do
    csv_path = resolve_csv_path_for_import

    puts "インポート開始: #{csv_path}"
    result = JpAddressComplement::Importers::CsvImporter.new(csv_path).import
    puts "インポート完了: upsert #{result.upserted} 件, 削除 #{result.deleted} 件"
  end
end

def resolve_csv_path_for_import
  if ENV['DOWNLOAD'] == '1'
    require 'jp_address_complement/ken_all_downloader'
    url = ENV.fetch('KEN_ALL_ZIP_URL', JpAddressComplement::KenAllDownloader::DEFAULT_URL)
    puts "ダウンロード中: #{url}"
    JpAddressComplement::KenAllDownloader.new(url).download_and_extract
  else
    csv_path = ENV.fetch('CSV', nil)
    if csv_path.nil?
      raise ArgumentError,
            'CSV 環境変数でファイルパスを指定するか、DOWNLOAD=1 で公式URLから取得してください。' \
            '例: rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV または DOWNLOAD=1'
    end
    csv_path
  end
end
