require 'spec_helper'
include Geocoder

describe Geocoder::Lookup::GoogleMap do

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
    GoogleMap.coordinates("25 Main St, Cooperstown, NY").first.to_i.should eq(42)
    GoogleMap.coordinates("25 Main St, Cooperstown, NY").last.to_i.should eq(-74)
  end

  def check_locations(address, loc)
    location = GoogleMap.locations(address).first
    if loc != nil && location != nil then
      location.street.should == loc.street
      location.city.should == loc.city
      location.state.should == loc.state
      location.zipcode.should == loc.zipcode
      location.lat.to_i.should == loc.lat.to_i
      location.lng.to_i.should == loc.lng.to_i
    end
  end

  it "request google locations to get standard full address" do
    pass = []
    pass << check_locations("Mountain, Leakey, ", Location.new({street: "Mountain", city: "Leakey", state: "TX", zipcode: "78873", lat: 29.727109, lng: -99.763538}))
    pass << check_locations("6454 East Taft, East Syracuse, ", Location.new({street: "6454 East Taft Road",city: "East Syracuse",state: "NY",zipcode: "13057",lat: 43.126749,lng: -76.074855}))
    pass << check_locations("Mountain View, , ", nil)
    pass << check_locations("White House 1600 DC", Location.new({street: "The White House,1600 Pennsylvania Avenue Northwest",city: "Washington",state: "DC",zipcode: "20500",lat: 38.898323,lng: -77.036656}))
    pass << check_locations("1600hiteatre, Mountain View, CA ", nil)
    pass << check_locations("Archer Daniels Midland Co.", Location.new({street: "2501 County Highway 1",city: "Decatur",state: "IL",zipcode: "62526",lat: 39.865423,lng: -88.89866}))
    pass << check_locations("1601 West Mission Boulevard #104, , ", Location.new({street: "1601 West Mission Boulevard #104", city: "Pomona", state: "CA", zipcode: "91766",lat: 34.055355,lng: -117.778059}))
    pass.select{|i| i}.size.should >= 3
    ap pass.select{|i| i}.size
  end
end