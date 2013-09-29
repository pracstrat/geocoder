require 'awesome_print'
require "geocoder/configuration"
require "geocoder/lookups/base"
require "geocoder/lookups/pc_miler"

module Geocoder

  def self.coordinates(address)
    ap lookup
  end

  def self.lookup
    Geocoder::Lookup.constantize(instance.lookup)
  end

  def self.instance
    Geocoder::Configuration.instance
  end
end