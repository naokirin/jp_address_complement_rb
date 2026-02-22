# frozen_string_literal: true

class AddressesController < ApplicationController
  def index
    @postal_code = params[:postal_code].to_s.strip
    @addresses = if @postal_code.present?
                  JpAddressComplement.search_by_postal_code(@postal_code)
                else
                  []
                end
  end
end
