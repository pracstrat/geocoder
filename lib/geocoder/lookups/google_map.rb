require 'base64'
require 'openssl'
require 'net/http'
require 'json'
module Geocoder
  module Lookup
    class GoogleMap < Base

      CHICAGO = [41.850033, -87.6500523]
      TIME = 1
      US_ADDRESS = /^(.*)\, (.*)\, ([[:upper:]]{2}) (\d+), USA$/

      DISTINCE = "http://maps.googleapis.com/maps/api/directions/json?origin=%s&destination=%s&region=us&sensor=false"

      def self.distance(from, to)
        from.gsub!(/\s+/,' ')
        to.gsub!(/\s+/,' ')
        from_to = [CGI::escape(from),CGI::escape(to)]
        time = 0.5
        ret = 0
        while(time <= TIME*3)
          begin
            Net::HTTP.start('maps.googleapis.com') do |http|
              http.read_timeout = time
              url = "/maps/api/directions/json?origin=%s&destination=%s&region=us&sensor=false"%from_to
              response = http.get(url)
              json = JSON.parse(response.body)
              if json["status"]=="OK"
                ap "222"
                ap json
                ret = json["routes"][0]["legs"][0]["distance"]["value"].to_i
                return ret
              else
              end
              sleep(time*2)
            end
          rescue Exception=>ex
            puts ex
            sleep(time*2)
          end
          time+=0.5
        end
        ret
      end

      def self.geocode_to_json(address)
        return nil if address.empty?
        time = 0.2
        while(time <= TIME)
          begin
            Net::HTTP.start('maps.googleapis.com') do |http|
              http.read_timeout = time
              response = http.get("/maps/api/geocode/json?address=%s&sensor=true&region=us"%CGI::escape(address))
              return JSON.parse(response.body)
            end
          rescue Exception=>ex
            time+=0.2
          end
        end
      end

      def self.locations(address)
        address_geocode = address.split(', ').map!{ |add| add.strip.empty? ? nil : add }.compact.join(', ')
        json = geocode_to_json(address_geocode)
        locations = []
        if json
          ret = []
          ret = json["results"].collect{|match|
            match["formatted_address"] if match["formatted_address"]=~US_ADDRESS
          } if json["status"] == "OK"
          locations = ret.compact.uniq.collect{|addr_from_google_map|
            loc = {}
            json = geocode_to_json(addr_from_google_map)
            loc = json["results"][0]["geometry"]["location"]  if json["status"] == "OK"
            Location.new({:address => addr_from_google_map, :lng => loc["lng"].round(6), :lat => loc["lat"].round(6)}) rescue nil
          }
        end
        locations.compact
      end

      def self.coordinates(address)
        return [] if address.empty?
        location = locations(address).first
        return [] if location.nil?
        [location.lat, location.lng]
      end

      def self.header
        '<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?sensor=false&language=en&region=US"></script>'
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
var directionsDisplay = new google.maps.DirectionsRenderer();
var directionsService = new google.maps.DirectionsService();
var chicago = new google.maps.LatLng(#{CHICAGO[0]}, #{CHICAGO[1]});
var myOptions = {
  zoom:7,
  mapTypeId: google.maps.MapTypeId.ROADMAP,
  center: chicago
}
var map = new google.maps.Map(document.getElementById('map'), myOptions);
directionsDisplay.setMap(map);
function requestRoutes(from, to, id, times){
  directionsService.route({
    origin: from,
    destination: to,
    travelMode: google.maps.DirectionsTravelMode.DRIVING, region: 'us'}, function(result, status){
      if(status==google.maps.DirectionsStatus.OK){
        var directionsRenderer = new google.maps.DirectionsRenderer();
        directionsRenderer.setMap(map);
        directionsRenderer.setDirections(result);
        loadedDirections(id, result, status);
      }else{
        if(times==5){
          requestDirectionsError(id, result, status);
        }else{
          requestRoutes(from, to, id, times+1);
        }
      }
  });
}
function clearDirections(){
  map = new google.maps.Map(document.getElementById('map'), myOptions);
  directionsDisplay.setMap(map);
}
JS
      end

    #'41.786579,-87.676547'
    #'525 Marie Dr, South Holland, IL'
      def self.request_directions(from, to, id)
<<JS
requestRoutes('#{from}', '#{to}', '#{id}', 1);
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