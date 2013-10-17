require 'base64'
require 'openssl'
require 'net/http'
require 'json'
require "geocoder/location"
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
        return nil if address.empty?
        address_geocode = address.split(', ').map!{ |add| add.strip.empty? ? nil : add }.compact.join(', ')
        json = geocode_to_json(address_geocode)
        locations = []
        if json
          ret = []
          ret = json["results"].collect{|match|
            match["formatted_address"] if match["formatted_address"]=~US_ADDRESS
          } if json["status"] == "OK"
          locations = ret.compact.uniq.collect{|addr_from_google_map|
            # ap addr_from_google_map
            addr = addr_from_google_map.split(',').map(&:strip)
            country = addr.pop
            state_zip = addr.pop
            city = addr.pop
            street = addr.join(',')
            # ap street
            state, zipcode = state_zip.split(' ').map(&:strip)
            loc = {}
            json = geocode_to_json(addr_from_google_map)
            loc = json["results"][0]["geometry"]["location"]  if json["status"] == "OK"
            Location.new({:street => street, :city => city, :state => state, :zipcode => zipcode, :lng => loc["lng"].round(6), :lat => loc["lat"].round(6)}) rescue nil
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
        '<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?sensor=false&language=en&region=US"></script>'
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

var mapAndRouteService = new function() {

  var directionsDisplay, directionsService, chicago, myOptions, map

  this.initTheMap = function () {
    directionsDisplay = new google.maps.DirectionsRenderer();
    directionsService = new google.maps.DirectionsService();
    chicago = new google.maps.LatLng(#{CHICAGO[0]}, #{CHICAGO[1]});

    myOptions = {
      zoom:7,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      center: chicago
    }

    map = new google.maps.Map(document.getElementById('map'), myOptions);
    directionsDisplay.setMap(map);
  }

  this.requestRoutes = function (from, to, id, times){
    directionsService.route({
        origin: from,
        destination: to,
        travelMode: google.maps.DirectionsTravelMode.DRIVING,
        region: 'us'
      }, function(result, status){
          if(status==google.maps.DirectionsStatus.OK){
            var directionsRenderer = new google.maps.DirectionsRenderer();
            directionsRenderer.setMap(map);
            directionsRenderer.setDirections(result);
            mapAndRouteService.loadedDirections(id, result.routes[0].legs[0].distance.value, result.routes[0].legs[0].end_address);
          }else{
            if (times == 5) {
              mapAndRouteService.requestDirectionsError();
            }else{
              mapAndRouteService.requestRoutes(from, to, id, times+1);
            }
          }
    });
  }

  this.clearDirections = function (){
    map = new google.maps.Map(document.getElementById('map'), myOptions);
    directionsDisplay.setMap(map);
  }

  this.loadedDirections = function(id, meters, dest){
    if(parseInt(meters) > 0){
      jQuery('#'+"#{instance.railmilesid}").val(jQuery("#rail_miles").val() + id+':'+meters + "|")
      jQuery('#'+"#{instance.destdetailid}").html(dest)
      jQuery('#'+"#{instance.destaddressid}").val(dest)
    }
    verifyRailMiles();
  }

  this.requestDirectionsError = function(){
    jQuery('#'+"#{instance.destdetailid}").html("Invalid Zip");
  }

}
mapAndRouteService.initTheMap();
JS
      end

      def self.request_directions(from, to, id)
<<JS
mapAndRouteService.requestRoutes('#{from}', '#{to}', '#{id}', 1);
JS
      end

      def self.clear_directions
<<JS
mapAndRouteService.clearDirections();
JS
      end
    end
  end
end