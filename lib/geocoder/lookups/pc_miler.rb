require 'base64'
require 'openssl'
require 'net/http'
require 'json'
require "geocoder/location"
module Geocoder
  module Lookup
    class PcMiler < Base

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
    end
  end
end