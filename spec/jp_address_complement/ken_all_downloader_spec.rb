# frozen_string_literal: true

require 'spec_helper'
require 'jp_address_complement/ken_all_downloader'
require 'stringio'
require 'tempfile'
require 'zip'

RSpec.describe JpAddressComplement::KenAllDownloader do
  def build_zip_with_csv(content = "col1,col2\n")
    buffer = StringIO.new
    Zip::OutputStream.write_buffer(buffer) do |zos|
      zos.put_next_entry(JpAddressComplement::KenAllDownloader::CSV_FILENAME)
      zos.write(content)
    end
    buffer.string
  end

  def create_zip_file_on_disk(entry_name, content)
    tmp = Tempfile.new(['spec_ken_all', '.zip'])
    tmp.close
    Zip::OutputStream.open(tmp.path) do |zos|
      zos.put_next_entry(entry_name)
      zos.write(content)
    end
    tmp.path
  end

  describe '#download_and_extract' do
    context 'when HTTP が成功し zip 内に KEN_ALL.CSV がある場合' do
      it '展開した CSV の絶対パスを返す' do
        zip_path_on_disk = create_zip_file_on_disk(
          JpAddressComplement::KenAllDownloader::CSV_FILENAME,
          "col1,col2\n"
        )
        downloader = described_class.new('https://example.com/ken_all.zip')
        allow(downloader).to receive(:download_zip).and_return(zip_path_on_disk)

        csv_path = downloader.download_and_extract

        expect(csv_path).to end_with(JpAddressComplement::KenAllDownloader::CSV_FILENAME)
        expect(File.exist?(csv_path)).to be true
        expect(File.read(csv_path)).to eq("col1,col2\n")
      ensure
        File.unlink(zip_path_on_disk) if zip_path_on_disk && File.exist?(zip_path_on_disk)
      end
    end

    context 'when HTTP が非 2xx を返す場合' do
      it 'DownloadError を発生させる' do
        response = instance_double(Net::HTTPResponse, code: '404', message: 'Not Found')
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

        http = instance_double(Net::HTTP)
        allow(http).to receive(:request) do |_req, &block|
          block.call(response)
        end
        allow(Net::HTTP).to receive(:start).and_yield(http)

        downloader = described_class.new('https://example.com/ken_all.zip')

        expect { downloader.download_and_extract }.to raise_error(
          JpAddressComplement::KenAllDownloader::DownloadError,
          /HTTP error: 404/
        )
      end
    end

    context 'when URL に host がない場合' do
      it 'DownloadError を発生させる' do
        uri_without_host = instance_double(URI::Generic, host: nil, port: nil, scheme: 'https')
        allow(URI).to receive(:parse).with('file:///local/path.zip').and_return(uri_without_host)

        downloader = described_class.new('file:///local/path.zip')

        expect { downloader.download_and_extract }.to raise_error(
          JpAddressComplement::KenAllDownloader::DownloadError,
          /host がありません/
        )
      end
    end

    context 'when ネットワークエラーが発生した場合' do
      it 'DownloadError でラップして発生させる' do
        allow(Net::HTTP).to receive(:start).and_raise(SocketError.new('getaddrinfo failed'))

        downloader = described_class.new('https://example.com/ken_all.zip')

        expect { downloader.download_and_extract }.to raise_error(
          JpAddressComplement::KenAllDownloader::DownloadError,
          /ダウンロードに失敗しました/
        )
      end
    end

    context 'when zip 内に KEN_ALL.CSV が含まれない場合' do
      it 'DownloadError を発生させる' do
        zip_path_on_disk = create_zip_file_on_disk('OTHER.TXT', 'dummy')
        downloader = described_class.new('https://example.com/ken_all.zip')
        allow(downloader).to receive(:download_zip).and_return(zip_path_on_disk)

        expect { downloader.download_and_extract }.to raise_error(
          JpAddressComplement::KenAllDownloader::DownloadError,
          /ZIP 内に #{JpAddressComplement::KenAllDownloader::CSV_FILENAME} が見つかりません/
        )
      ensure
        File.unlink(zip_path_on_disk) if zip_path_on_disk && File.exist?(zip_path_on_disk)
      end
    end

    context 'when ZIP エントリがパストラバーサルを含む場合（Zip Slip 対策）' do
      it 'パストラバーサルのエントリをスキップし CSV は正常に展開される' do
        zip_path_on_disk = Tempfile.new(['spec_ken_all', '.zip']).tap(&:close).path
        Zip::OutputStream.open(zip_path_on_disk) do |zos|
          zos.put_next_entry('../../evil.txt')
          zos.write('evil content')
          zos.put_next_entry(JpAddressComplement::KenAllDownloader::CSV_FILENAME)
          zos.write("col1,col2\n")
        end

        downloader = described_class.new('https://example.com/ken_all.zip')
        allow(downloader).to receive(:download_zip).and_return(zip_path_on_disk)

        csv_path = downloader.download_and_extract

        expect(File.exist?(csv_path)).to be true
        expect(File.read(csv_path)).to eq("col1,col2\n")
      ensure
        File.unlink(zip_path_on_disk) if zip_path_on_disk && File.exist?(zip_path_on_disk)
      end

      it 'パストラバーサルのエントリのみの場合は DownloadError を発生させる' do
        zip_path_on_disk = Tempfile.new(['spec_ken_all', '.zip']).tap(&:close).path
        Zip::OutputStream.open(zip_path_on_disk) do |zos|
          zos.put_next_entry('../../evil.txt')
          zos.write('evil content')
        end

        downloader = described_class.new('https://example.com/ken_all.zip')
        allow(downloader).to receive(:download_zip).and_return(zip_path_on_disk)

        expect { downloader.download_and_extract }.to raise_error(
          JpAddressComplement::KenAllDownloader::DownloadError,
          /ZIP 内に #{JpAddressComplement::KenAllDownloader::CSV_FILENAME} が見つかりません/
        )
      ensure
        File.unlink(zip_path_on_disk) if zip_path_on_disk && File.exist?(zip_path_on_disk)
      end
    end

    context 'when zip が壊れている場合' do
      it 'DownloadError でラップして発生させる' do
        # body_io は Net::HTTPResponse の内部 API のため instance_double は使わない
        # rubocop:disable RSpec/VerifiedDoubles
        response = double('HTTPResponse', body_io: StringIO.new('not a zip'), code: '200', message: 'OK')
        # rubocop:enable RSpec/VerifiedDoubles
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        http = instance_double(Net::HTTP)
        allow(http).to receive(:request) do |_req, &block|
          block.call(response)
        end
        allow(Net::HTTP).to receive(:start).and_yield(http)

        downloader = described_class.new('https://example.com/ken_all.zip')

        expect { downloader.download_and_extract }.to raise_error(
          JpAddressComplement::KenAllDownloader::DownloadError,
          /ZIP の展開に失敗しました/
        )
      end
    end

    # branch coverage: fetch_to_path で明示的 port を使う URL（uri.port が truthy）
    context 'when URL に明示的な port が含まれる場合' do
      it 'その port で Net::HTTP.start が呼ばれる' do
        zip_content = build_zip_with_csv("col1,col2\n")
        # rubocop:disable RSpec/VerifiedDoubles
        response = double('HTTPResponse', body: zip_content, code: '200', message: 'OK')
        # rubocop:enable RSpec/VerifiedDoubles
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        http = instance_double(Net::HTTP)
        allow(http).to receive(:request) do |_req, &block|
          block.call(response)
        end
        allow(Net::HTTP).to receive(:start).with('example.com', 8443, hash_including(use_ssl: true)).and_yield(http)

        downloader = described_class.new('https://example.com:8443/ken_all.zip')
        csv_path = downloader.download_and_extract
        expect(File.exist?(csv_path)).to be true
        expect(File.read(csv_path)).to eq("col1,col2\n")
      end
    end

    # branch coverage: fetch_to_path で http スキーム（port 80）
    context 'when http スキームの URL の場合' do
      it 'port 80 で接続してダウンロードできる' do
        zip_content = build_zip_with_csv("col1\n")
        # rubocop:disable RSpec/VerifiedDoubles
        response = double('HTTPResponse', body: zip_content, code: '200', message: 'OK')
        # rubocop:enable RSpec/VerifiedDoubles
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        http = instance_double(Net::HTTP)
        allow(http).to receive(:request) do |_req, &block|
          block.call(response)
        end
        allow(Net::HTTP).to receive(:start).with('example.com', 80, hash_including(use_ssl: false)).and_yield(http)

        downloader = described_class.new('http://example.com/ken_all.zip')
        csv_path = downloader.download_and_extract
        expect(File.exist?(csv_path)).to be true
      end
    end
  end

  describe '#initialize' do
    it 'URL を省略した場合は DEFAULT_URL を使う' do
      downloader = described_class.new
      expect(downloader.instance_variable_get(:@url)).to eq(described_class::DEFAULT_URL)
    end

    it 'URL を渡した場合はその URL を使う' do
      downloader = described_class.new('https://custom.example/zip')
      expect(downloader.instance_variable_get(:@url)).to eq('https://custom.example/zip')
    end
  end
end
