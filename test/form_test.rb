require_relative "test_helper"

class ExampleForm
  include AwesomeForm::Form
end

describe ExampleForm, "Example form mimicking user sign up" do

  subject { ExampleForm.new }

  describe ".fields" do
    it "takes names of fields to define on the form" do
      ExampleForm.fields :field_1, :field_2
      value_1, value_2 = :value_1, :value_2
      subject.field_1 = value_1
      subject.field_2 = value_2
      assert_equal subject.field_1, value_1
      assert_equal subject.field_2, value_2
    end
  end

  describe "#valid?" do
    it "runs validations and records the errors" do
      ExampleForm.fields :field
      ExampleForm.validates :field, presence: true

      subject.field = nil
      refute subject.valid?
      assert subject.errors[:field].include?("can't be blank")
    end
  end

  describe ".wraps" do
    let(:slinky) { :some_object }

    it "declares an object the form wraps" do
      ExampleForm.wraps :slinky do; end
      subject.slinky = slinky
      assert_equal subject.slinky, slinky
    end

    it "takes a block to execute for configuration" do
      catch(:ran) do
        ExampleForm.wraps(:slinky) { throw :ran }
        raise "This line should not execute"
      end
    end

    describe "#assigns" do
      it "configures fields to be assigned to the model on validation" do
        class Model
          attr_accessor :model_field
        end
        ExampleForm.fields :form_field
        ExampleForm.wraps :model do
          assigns model_field: :form_field
        end

        model = Model.new
        subject = ExampleForm.new(form_field: :some_value, model: model)
        subject.valid?
        assert_equal model.model_field, :some_value
      end
    end
  end

  # describe "#save"
end
