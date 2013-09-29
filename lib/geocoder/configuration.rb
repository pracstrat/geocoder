require 'singleton'

module Geocoder

  def self.configure(options=nil)
    if options.nil?
      Configuration.instance
    else
      Configuration.instance.configure(options)
    end
  end

  class Configuration
    
    include Singleton
    
    OPTIONS = [
      :lookup,
      :username,
      :password,
      :account    
    ]

    attr_accessor :data

    def initialize
      @data = {}
      set_defaults
    end

    def configure(options)
      @data.merge!(options)
    end

    OPTIONS.each do |o|
      define_method o do
        @data[o]
      end
      define_method "#{o}=" do |value|
        @data[o] = value
      end
    end

    private
    def set_defaults
      @data[:lookup] = :pc_miler
      @data[:username] = nil
      @data[:password] = nil
      @data[:account] = nil
    end
  end
end