require 'awesome_print'
require "geocoder/configuration"
require "geocoder/lookups/base"
require "geocoder/lookups/pc_miler"
require "geocoder/location"
require "geocoder/lookups/google_map"
require 'active_support'

module Geocoder

  def self.coordinates(address)
    lookup.coordinates(address)
  end

  def self.lookup
    class_name = ActiveSupport::Inflector.classify(instance.lookup)
    ActiveSupport::Inflector.constantize("Geocoder::Lookup::#{class_name}")
  end

  def self.locations(address)
    lookup.locations(address)
  end

  def self.distance(ori, dest)
    lookup.distance(ori, dest)
  end

  def self.instance
    Geocoder::Configuration.instance
  end

  def self.header
    lookup.header
  end

  def self.show
    lookup.show
  end

  def self.request_directions(from, to, id)
    lookup.request_directions(from, to, id)
  end

  def self.clear_directions
    lookup.clear_directions
  end
end