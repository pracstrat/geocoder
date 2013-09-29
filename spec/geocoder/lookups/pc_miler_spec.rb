require 'spec_helper'
include Geocoder::Lookup

describe PcMiler do
  # it "address to json" do 
  #   expected = {"street" => "528 Marie Dr", "city" => "South Holland", "state" => "IL", "postcode" => 60473}
  #   PcMiler.hash_address("528 Marie Dr, South Holland, IL 60473").should eq(expected)
  #   expected = {"street" => nil, "city" => nil, "state" => "IL", "postcode" => 60473}
  #   PcMiler.hash_address(", , IL 60473").should eq(expected)
  # end

  it "locations" do
    locations = PcMiler.locations("street" => "528 Marie Dr", "city" => "South Holland", "state" => "IL", "postcode" => 60473)
    locations.first["Coords"].should == {
      "Lat" => "41.594123",
      "Lon" => "-87.603162"
    }
    PcMiler.locations("street" => "528 Marie").should be_empty
    PcMiler.locations("street" => "Marie Dr", "city" => "South Holland", "state" => "IL", "list" => 10).size.should eq(2)
  end

  it "coordinate" do
    PcMiler.coordinate({
      "street" => "528 Marie Dr", "city" => "South Holland", "state" => "IL", "postcode" => 60473
    }).should eq([41.594123, -87.603162])
    PcMiler.coordinate({
      "street" => "528 Marie Dr"
    }).should be_nil
  end

  describe "fetch mileage" do 
    let(:from){
      { "street" => "26664 Baseline Rd", "city" => "Elwood", "state" => "IL", "postcode" => 60421 }
    }
    let(:to){
      { "street" => "7000 West 71st Street", "city" => "Chicago", "state" => "IL", "postcode" => 60638 }
    }

    it "mileage" do 
      PcMiler.mileage(from, to).should eq(["0:49", "42.8"])
    end

    it "distance" do 
      PcMiler.distance(from, to).should eq(42.8)
    end
  end
end
