# frozen_string_literal: true
# rbs_inline: enabled

require 'fileutils'
require 'net/http'
require 'tempfile'
require 'tmpdir'
require 'uri'
require 'zip'

module JpAddressComplement
  # 郵便番号データ（ken_all.zip）を公式URLからダウンロードし、展開して CSV のパスを返す
  class KenAllDownloader
    # @rbs String
    DEFAULT_URL = 'https://www.post.japanpost.jp/zipcode/dl/oogaki/zip/ken_all.zip'
    # @rbs String
    CSV_FILENAME = 'KEN_ALL.CSV'

    class DownloadError < JpAddressComplement::Error; end

    # @rbs (?String url) -> void
    # @param url [String] ダウンロードする zip の URL（省略時は DEFAULT_URL）
    def initialize(url = DEFAULT_URL)
      @url = url
    end

    # zip をダウンロードして一時ディレクトリに展開し、KEN_ALL.CSV の絶対パスを返す。
    # 呼び出し元でインポート完了まで一時ディレクトリは削除されない（プロセス終了時に OS が削除）。
    # @rbs () -> String
    # @return [String] 展開された KEN_ALL.CSV の絶対パス
    # @raise [DownloadError] ダウンロード・展開・ファイルが見つからない場合
    def download_and_extract
      zip_path = download_zip
      extract_zip(zip_path)
    ensure
      File.unlink(zip_path) if zip_path && File.exist?(zip_path)
    end

    private

    # @rbs () -> String
    def download_zip
      tmp = Tempfile.new(['ken_all', '.zip'])
      tmp.binmode
      tmp.close
      path = tmp.path or raise 'Tempfile#path is nil'
      fetch_to_path(path)
      path
    rescue SocketError, Timeout::Error, Errno::ENOENT => e
      raise DownloadError, "ダウンロードに失敗しました: #{e.message}"
    end

    # @rbs (String path) -> void
    def fetch_to_path(path)
      uri = URI.parse(@url)
      host = uri.host or raise DownloadError, "URL に host がありません: #{@url}"
      port = uri.port || (uri.scheme == 'https' ? 443 : 80)
      use_ssl = uri.scheme == 'https'
      Net::HTTP.start(host, port, use_ssl: use_ssl, read_timeout: 60, open_timeout: 10) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request) { |response| write_response_to_path(response, path) }
      end
    end

    # @rbs (Net::HTTPResponse response, String path) -> void
    def write_response_to_path(response, path)
      raise DownloadError, "HTTP error: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      File.open(path, 'wb') { |f| IO.copy_stream(response.body_io, f) }
    end

    # @rbs (String zip_path) -> String
    def extract_zip(zip_path)
      tmpdir = Dir.mktmpdir('jp_address_complement_ken_all')
      csv_path = extract_zip_entries(zip_path, tmpdir)
      csv_path ||= find_csv_in_dir(tmpdir)
      raise DownloadError, "ZIP 内に #{CSV_FILENAME} が見つかりません" if csv_path.nil?

      csv_path
    rescue Zip::Error => e
      raise DownloadError, "ZIP の展開に失敗しました: #{e.message}"
    end

    # @rbs (String zip_path, String tmpdir) -> String?
    def extract_zip_entries(zip_path, tmpdir)
      csv_path = nil
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          name = entry.name.delete_prefix('/')
          dest = File.join(tmpdir, name)
          FileUtils.mkdir_p(File.dirname(dest))
          entry.extract(dest) { true } # 上書き許可
          csv_path = dest if entry_csv?(name, dest)
        end
      end
      csv_path
    end

    # @rbs (String entry_name, String dest) -> bool
    def entry_csv?(entry_name, dest)
      File.basename(entry_name) == CSV_FILENAME && File.file?(dest)
    end

    # @rbs (String tmpdir) -> String?
    def find_csv_in_dir(tmpdir)
      Dir.glob(File.join(tmpdir, '**', CSV_FILENAME)).find { |p| File.file?(p) }
    end
  end
end
