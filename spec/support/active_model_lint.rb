# http://library.edgecase.com/activemodel-lint-test-for-rspec

shared_examples_for "ActiveModel" do
  include ActiveModel::Lint::Tests

  def model
    subject
  end

  ActiveModel::Lint::Tests.public_instance_methods
    .map { |m| m.to_s }
    .grep(/^test/)
    .each do |m|
      example m.gsub('_',' ') do
        send m
      end
    end
end
