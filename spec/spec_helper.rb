$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'simplecov'
require 'geocoder'
require 'awesome_print'

SimpleCov.start

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end

Geocoder.configure({
  lookup: :google_map,
  username: "R2R",
  password: "R2R103338",
  account: "R2RIntermodal_test",
  apikey: "E61C0420C148D141BA45A25B1B5501FD"
})
