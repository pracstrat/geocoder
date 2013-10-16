require 'base64'
require 'openssl'
require 'net/http'
require 'json'
require "geocoder/location"
module Geocoder
  module Lookup
    class PcMiler < Base

      CHICAGO = [41.850033, -87.6500523]
      DIGEST = OpenSSL::Digest::Digest.new("sha256")
      BASE = "http://pcmiler.alk.com/APIs/REST/v0.5/Service.svc"

      def self.hash_address(address)
        # I am not suggesting this is the best way. I think the best way actually is to change Company.address inside of TZ!
        if address =~ /(.*), (.*), (.*) ((\d|-)*)/
          { street: $1, city: $2, state: $3, postcode: $4, list: 10 }
        elsif address =~ /(.*), (.*), (.*)/
          { street: $1, city: $2, state: $3 , list: 10}
        else
          { }
        end
      end

      def self.generate_hash(request, time_stamp)
        computed_hash = OpenSSL::HMAC.digest(DIGEST, instance.password, request + time_stamp)
        encoded = Base64.encode64(computed_hash)
        "SHA256 #{instance.account}:#{instance.username}:#{encoded}"
      end

      def self.headers(uri)
        httpdate = Time.now.httpdate
        { "Authorization" => generate_hash(uri.path, httpdate), "authDate" => httpdate }
      end

      def self.locations(address)
        options = hash_address(address)
        return nil if options.empty?
        locations = []
        query = options.map{|key, value| "#{key}=#{CGI::escape(value.to_s)}" }.join("&")
        uri = URI::parse("#{BASE}/locations?#{query}")
        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            response = http.request_get(uri.request_uri, headers(uri))
            ret = JSON.parse(response.body) if response.code.to_i == 200
            # ap ret
            locations = ret.compact.uniq.collect{|whole_Address|
              Location.new({:street => whole_Address['Address']['StreetAddress'], :city => whole_Address['Address']['City'], :state => whole_Address['Address']['State'], :zipcode => whole_Address['Address']['Zip'], lng: whole_Address['Coords']['Lon'].to_f, lat: whole_Address['Coords']['Lat'].to_f})
            }.compact
          end
        rescue Exception => ex
          puts ex
          ex.to_s
        end
        locations.compact
      end

      def self.coordinates(address)
        return nil if address.empty?
        unless locations(address).nil?
          locations(address).map{|loc|
            lat = loc.lat.to_f rescue nil
            lon = loc.lng.to_f rescue nil
            [ lat, lon ]
          }.first
        else
          nil
        end
      end

      def self.mileage(ori, dest)
        ori = coordinates(ori)
        dest = coordinates(dest)
        uri = URI::parse("#{BASE}/mileage")

        body = {
          "Request" => {
            "Coordinates" => [
              ori.reverse,
              dest.reverse
            ]
          }
        }.to_json

        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            response = http.request_post(uri.request_uri, body, headers(uri).merge("Content-Type" => "text/json"))
            response.body.gsub(/"/, "").split(",")
          end
        rescue Exception=>ex
          ex.to_s
        end
      end

      def self.distance(ori, dest)
        (mileage(ori, dest).last.to_f * 1609.344).round(2) rescue nil
      end

      def self.header
        '<script src="http://maps.alk.com/api/1.0/ALKMaps.js" type="text/javascript"></script>'
      end

      def self.show
<<JS
<script type="text/javascript">
#{init_script}
</script>
JS
      end

      def self.init_script
<<JS
var map, layer;
var lon = #{CHICAGO.last}, lat = #{CHICAGO.first}, zoom = 3;
ALKMaps.APIKey = "#{instance.apikey}";
map = new ALKMaps.Map('map');
layer = new ALKMaps.Layer.BaseMap("ALK Maps", {}, {displayInLayerSwitcher: false});
map.addLayer(layer);
var lonlat = new ALKMaps.LonLat(lon,lat);
map.setCenter(lonlat, zoom);
var routeIdIndex = 0;
var routeIds = new Array();

var routingLayer = new ALKMaps.Layer.Routing( "Route Layer");

function clearDirections() {

  for (var i=0; i<=routeIdIndex; i++)
  {
    routingLayer.removeRoute(routeIds[i]);
  }
  routeIdIndex = 0;
  routeIds = new Array();
  routingLayer = new ALKMaps.Layer.Routing( "Route Layer");
}

function requestRoutes(origin, dest, id) {
  routeIds[routeIdIndex] = id;
  routingLayer.addRoute({
    stops: [
      new ALKMaps.LonLat(origin[1], origin[0]),
      new ALKMaps.LonLat(dest[1], dest[0])
    ],
    functionOptions:{
      routeId: id,
      async: true
    },
    routeOptions: {
      highwayOnly: false,
      tollDiscourage: true
    },
    reportOptions: {
      type: "mileage",
      format: "json"
    }
  });

  map.addLayer(routingLayer);
  routeIdIndex = routeIdIndex + 1;
}
JS
      end

      def self.request_directions(from, to, id)
        street = ''
        city   = ''
        state  = ''
        zipcode = to
        address = "#{street}, #{city}, #{state} #{zipcode}"
        dest = coordinates(address)
        origin = from.split(',').map(&:to_f)
<<JS
requestRoutes([#{origin[0].to_f}, #{origin[1].to_f}], [#{dest[0].to_f}, #{dest[1].to_f}], '#{id}');
JS
      end

      def self.clear_directions
<<JS
clearDirections();
JS
      end
    end
  end
end