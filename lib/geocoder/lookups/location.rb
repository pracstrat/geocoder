class Location
  attr_accessor :street, :city, :state, :zipcode, :lng, :lat
  def initialize(options={})
    options.each{|k,v| instance_variable_set("@#{k.to_s}", v)}
  end
end