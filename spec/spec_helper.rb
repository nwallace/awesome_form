require "minitest/autorun"
require "active_model"
require "pry"

I18n.enforce_available_locales = false

require_relative "support/active_model_lint"

require_relative "../lib/awesome_form"

RSpec.configure do |config|
  config.expect_with :rspec, :minitest
end
