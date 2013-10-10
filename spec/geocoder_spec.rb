require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Geocoder" do

  it '.coordinates' do
    Geocoder.coordinates("25 Main St, Cooperstown, NY").should eq([42.700118, -74.922652])
  end

  it '.distance' do
    from = "26664 Baseline Rd, Elwood, IL 60421"
    to = "7000 West 71st Street, Chicago, IL 60638"
    puts ">>>>>>>>>>>>>>>>>>>>>>>>>focus here ***********************"
    Geocoder.distance(from, to).should eq(68879.92)
    puts "<<<<<<<<<<<<<<<<<<<<<<<<<focus here ***********************"
  end

  it ".locations" do
    locations = Geocoder.locations("528 Marie Dr, South Holland, IL 60473")
    locations.first.lng.should == -87.603162
    locations.first.lat.should == 41.594123

    Geocoder.locations("528 Marie").should be_nil
    Geocoder.locations("Marie Dr, South Holland, IL").size.should eq(2)
  end
end
