require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Geocoder" do
  
  it '.coordinates' do 
    Geocoder.coordinates("25 Main St, Cooperstown, NY").should eq([42.700118, -74.922652])
  end
end
