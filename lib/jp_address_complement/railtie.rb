# frozen_string_literal: true

require 'rails'

module JpAddressComplement
  # Rails との統合を担う Railtie
  class Railtie < Rails::Railtie
    railtie_name :jp_address_complement

    rake_tasks do
      load File.expand_path('../../tasks/jp_address_complement.rake', __dir__)
    end

    initializer 'jp_address_complement.setup_repository' do
      require_relative 'repositories/active_record_postal_code_repository'
      require_relative 'models/postal_code'
      JpAddressComplement.configuration.repository ||=
        Repositories::ActiveRecordPostalCodeRepository.new
    end

    generators do
      require_relative '../../generators/jp_address_complement/install_generator'
    end
  end
end
