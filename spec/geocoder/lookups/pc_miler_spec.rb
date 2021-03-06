require 'spec_helper'
include Geocoder::Lookup

describe PcMiler do
  it "address to json" do
    # ap GoogleMap::CHICAGO
    expected = { street: "528 Marie Dr", city: "South Holland", state: "IL", postcode: "60473", list: 10 }
    PcMiler.hash_address("528 Marie Dr, South Holland, IL 60473").should eq(expected)

    expected = { street: "", city: "", state: "IL", postcode: "60473", list: 10 }
    PcMiler.hash_address(", , IL 60473").should eq(expected)
  end

  it "locations" do
    locations = PcMiler.locations("528 Marie Dr, South Holland, IL 60473")
    locations.first.street.should == "528 Marie Drive"
    locations.first.city.should == "South Holland"
    locations.first.state.should == "IL"
    locations.first.zipcode.should == "60473"
    locations.first.lng.should == -87.603162
    locations.first.lat.should == 41.594123
    PcMiler.locations("528 Marie").should be_nil
    PcMiler.locations("Marie Dr, South Holland, IL").size.should eq(2)
  end

  it "coordinate" do
    PcMiler.coordinates("528 Marie Dr, South Holland, IL 60473").should eq([41.594123, -87.603162])
    PcMiler.coordinates("528 Marie Dr").should be_nil
  end

  describe "fetch mileage" do
    let(:from) { "26664 Baseline Rd, Elwood, IL 60421" }
    let(:to) { "7000 West 71st Street, Chicago, IL 60638" }

    it "mileage" do
      PcMiler.mileage(from, to).should eq(["0:49", "42.8"])
    end

    it "distance" do
      PcMiler.distance(from, to).should eq(68879.92)
    end
  end
end
