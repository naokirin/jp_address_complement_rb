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

  def prefix
    @prefix = params[:prefix].to_s.strip
    @addresses = if @prefix.present? && @prefix.length >= 4
                   JpAddressComplement.search_by_postal_code_prefix(@prefix)
                 else
                   []
                 end
  end

  def validate
    @postal_code = params[:postal_code].to_s.strip
    @address = params[:address].to_s.strip
    if @postal_code.present? && @address.present?
      @valid = JpAddressComplement.valid_combination?(@postal_code, @address)
    else
      @valid = nil
    end
  end

  def prefecture
    @code = params[:code].to_s.strip
    @name = params[:name].to_s.strip
    @code_to_name = nil
    @name_to_code = nil
    if @code.present?
      @code_to_name = JpAddressComplement.prefecture_name_from_code(@code)
    end
    if @name.present?
      @name_to_code = JpAddressComplement.prefecture_code_from_name(@name)
    end
  end

  def reverse
    @pref = params[:pref].to_s.strip
    @city = params[:city].to_s.strip
    @town = params[:town].to_s.strip
    if @pref.present? && @city.present?
      @postal_codes = JpAddressComplement.search_postal_codes_by_address(
        pref: @pref,
        city: @city,
        town: @town.presence
      )
    else
      @postal_codes = []
    end
  end
end
