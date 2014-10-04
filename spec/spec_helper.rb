require "minitest/autorun"
require "active_model"
require "pry"

I18n.enforce_available_locales = false

Dir[File.dirname(__FILE__) + "/../lib/**/*.rb"].each { |file| require file }
