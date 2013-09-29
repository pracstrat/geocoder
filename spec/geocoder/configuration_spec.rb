require 'spec_helper'

describe Geocoder do 


  describe Geocoder::Configuration do 
    it "initialize" do 
      instance = Geocoder::Configuration.instance
      instance.lookup.should eq(:pc_miler)
      instance.configure({:username => "user"})
      instance.lookup.should eq(:pc_miler)
      instance.username.should eq("user")
    end
  end

  it "configure" do 
    instance = Geocoder::Configuration.instance
    instance.lookup.should eq(:pc_miler)
    Geocoder.configure({:username => "user", :password => "password"})
    instance.lookup.should eq(:pc_miler)
    instance.username.should eq("user")
    instance.password.should eq("password")
  end

end