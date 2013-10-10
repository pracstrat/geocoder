require 'spec_helper'
# require 'google_map'
include Geocoder::Lookup

describe GoogleMap do

  it "should load head" do
    GoogleMap.header.should == '<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?sensor=false&language=en&region=US"></script>'
  end

  it "script show the map" do
    expected=<<JS
<script type="text/javascript">
#{GoogleMap.init_script}
</script>
JS

    GoogleMap.show.gsub(/\s/,'').should == expected.gsub(/\s/,'')
  end

  it "should request direction" do
    js=<<JS
requestRoutes('41.786579,-87.676547', '525 Marie Dr, South Holland, IL', 'rr1', 1);
JS

    GoogleMap.request_directions('41.786579,-87.676547','525 Marie Dr, South Holland, IL', 'rr1').gsub(/\s/,'').should == js.gsub(/\s/,'')
  end

  it "should get init script" do
    js=<<JS
var directionsDisplay = new google.maps.DirectionsRenderer();
var directionsService = new google.maps.DirectionsService();
var chicago = new google.maps.LatLng(41.850033, -87.6500523);
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

    GoogleMap.init_script.gsub(/\s/,'').should == js.gsub(/\s/,'')
  end

  it "get the coordinates from google" do
    GoogleMap.coordinates("25 Main St, Cooperstown, NY").should eq([42.700118, -74.922652])
  end

  def check_locations(address, expected)
    GoogleMap.locations(address).map{|loc| [loc.address, loc.lat, loc.lng]} == expected
  end

  it "request google locations to get standard full address" do
    pass = []
    # VCR.use_cassette("google_map_geocoder") do
      pass << check_locations("Mountain, Leakey, ", [["Mountain, Leakey, TX 78873, USA", 29.727109, -99.763538]])
      pass << check_locations("6454 East Taft, East Syracuse, ", [["6454 East Taft Road, East Syracuse, NY 13057, USA", 43.126749, -76.074855]])
      pass << check_locations("Mountain View, , ", [])
      pass << check_locations("White House 1600 DC", [["The White House, 1600 Pennsylvania Avenue Northwest, Washington, DC 20500, USA", 38.898323, -77.036656]])
      pass << check_locations("1600hiteatre, Mountain View, CA ", [])
      pass << check_locations("Archer Daniels Midland Co.", [["Adm, 2501 County Highway 1, Decatur, IL 62526, USA", 39.865423, -88.89866]])
      pass << check_locations("1601 West Mission Boulevard #104, , ", [["1601 West Mission Boulevard #104, Pomona, CA 91766, USA", 34.055355, -117.778059]])
    # end
    pass.select{|i| i}.size.should >= 3
  end
end