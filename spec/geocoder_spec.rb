require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Geocoder" do

  it '.coordinates' do
    Geocoder.coordinates("25 Main St, Cooperstown, NY").first.to_i.should eq(42)
    Geocoder.coordinates("25 Main St, Cooperstown, NY").last.to_i.should eq(-74)
  end

  it '.distance' do
    from = "26664 Baseline Rd, Elwood, IL 60421"
    to = "7000 West 71st Street, Chicago, IL 60638"
    Geocoder.distance(from, to).should eq(68879.92)
  end

  it ".locations" do
    locations = Geocoder.locations("528 Marie Dr, South Holland, IL 60473")
    locations.first.street.should == "528 Marie Drive"
    locations.first.city.should == "South Holland"
    locations.first.state.should == "IL"
    locations.first.zipcode.should == "60473"
    locations.first.lat.to_i.should == 41
    locations.first.lng.to_i.should == -87
    Geocoder.locations("528 Marie").should be_nil
    Geocoder.locations("Marie Dr, South Holland, IL").size.should eq(2)
  end
end
