# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JpAddressComplement::Repositories::PostalCodeRepository do
  describe '#find_by_code' do
    it 'NotImplementedError を発生させる' do
      repo = described_class.new
      expect { repo.find_by_code('1000001') }.to raise_error(NotImplementedError)
    end
  end

  describe '#find_by_prefix' do
    it 'NotImplementedError を発生させる' do
      repo = described_class.new
      expect { repo.find_by_prefix('1000') }.to raise_error(NotImplementedError)
    end
  end
end
