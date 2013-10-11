module Geocoder
  module Lookup
    class Base
      def self.instance
        Geocoder::Configuration.instance
      end
    end
  end
end