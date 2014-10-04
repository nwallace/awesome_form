require_relative "spec_helper"

class ExampleForm
  include AwesomeForm::Form
end
class ExampleModel
  attr_accessor :model_field
end

RSpec.describe ExampleForm do

  subject { ExampleForm.new }

  describe ".fields" do
    it "takes names of fields to define on the form" do
      ExampleForm.fields :field_1, :field_2
      value_1, value_2 = :value_1, :value_2
      subject.field_1 = value_1
      subject.field_2 = value_2
      expect(subject.field_1).to eq value_1
      expect(subject.field_2).to eq value_2
    end
  end

  describe "#valid?" do
    it "runs validations and records the errors from form validations" do
      ExampleForm.fields :field
      ExampleForm.validates :field, presence: true

      subject.field = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:field]).to include "can't be blank"
    end
  end

  describe ".wraps" do
    let(:slinky) { double("Some object") }

    it "declares an object the form wraps" do
      ExampleForm.wraps :slinky do; end
      subject.slinky = slinky
      expect(subject.slinky).to eq slinky
    end

    it "takes a block to execute for configuration" do
      expect {
        catch(:ran) do
          ExampleForm.wraps(:slinky) { throw :ran }
          raise "This line should not execute"
        end
      }.not_to raise_error
    end

    describe "#assigns" do
      let(:model) { ExampleModel.new }
      let(:value) { double("some value") }

      before do
        ExampleForm.fields :form_field
      end

      it "configures fields to be assigned to the model on validation" do
        ExampleForm.wraps :model do
          assigns model_field: :form_field
        end
        subject = ExampleForm.new(form_field: value, model: model)
        subject.valid?
        expect(model.model_field).to eq value
      end

      it "can use procs for more complex assignments" do
        ExampleForm.wraps :model do
          assigns model_field: -> { "something else" }
        end
        subject = ExampleForm.new(form_field: value, model: model)
        subject.valid?
        expect(model.model_field).to eq "something else"
      end

      it "the procs can take the form as an argument" do
        ExampleForm.wraps :model do
          assigns model_field: ->(form) {
            raise "unexpected argument to proc!" unless form.class == ExampleForm
            "another value"
          }
        end
        subject = ExampleForm.new(form_field: value, model: model)
        subject.valid?
        expect(model.model_field).to eq "another value"
      end

      it "the procs can take the form and the wrapped model as arguments" do
        ExampleForm.wraps :model do
          assigns model_field: ->(form, model) {
            raise "unexpected argument to proc!" unless form.class == ExampleForm
            raise "unexpected argument to proc!" unless model.class == ExampleModel
            "yet more"
          }
        end
        subject = ExampleForm.new(form_field: value, model: model)
        subject.valid?
        expect(model.model_field).to eq "yet more"
      end
    end
  end

  # describe "#save"
end
