require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Geocoder" do

  it '.coordinates' do
    ap Geocoder.coordinates("25 Main St, Cooperstown, NY")
    Geocoder.coordinates("25 Main St, Cooperstown, NY").should eq([42.700118, -74.922652])
  end

  it '.distance' do
    from = "26664 Baseline Rd, Elwood, IL 60421"
    to = "7000 West 71st Street, Chicago, IL 60638"

    Geocoder.distance(from, to).should eq(42.8)
  end

  it ".locations" do
    locations = Geocoder.locations("street" => "528 Marie Dr", "city" => "South Holland", "state" => "IL", "postcode" => 60473)
    locations.first["Coords"].should == {
      "Lat" => "41.594123",
      "Lon" => "-87.603162"
    }
    Geocoder.locations("street" => "528 Marie").should be_empty
    Geocoder.locations("street" => "Marie Dr", "city" => "South Holland", "state" => "IL", "list" => 10).size.should eq(2)
  end
end
