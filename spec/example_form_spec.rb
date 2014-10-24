require_relative "spec_helper"

class ExampleForm
  include AwesomeForm::Form

  no_arg = -> {
    "no-arg proc"
  }
  one_arg = ->(form) {
    raise unless form.is_a?(ExampleForm)
    "one-arg proc"
  }
  two_arg = ->(form, model) {
    raise unless form.is_a?(ExampleForm)
    raise unless model.is_a?(ExampleModel)
    "two-arg proc"
  }
  assign_field_2 = ->(form) {
    raise unless form.is_a?(ExampleForm)
    form.field_2 = "one-arg proc reverse"
  }
  assign_field_3 = ->(form, model) {
    raise unless form.is_a?(ExampleForm)
    raise unless model.is_a?(ExampleModel)
    form.field_3 = "two-arg proc reverse"
  }

  fields :field_1, :field_2, :field_3, :field_4, :field_5, :field_6
  validates :field_1, presence: true
  wraps :model, use_for_naming: true do
    assigns :model_field_1, to: :field_1
    assigns :model_field_2, to: no_arg, reverse: assign_field_2
    assigns :model_field_3, to: one_arg, reverse: assign_field_3
    assigns :model_field_4, to: two_arg
    assigns :model_field_5, to: :field_5, include_errors: true, reverse: :field_6
    assigns :model_field_6, to: :field_6, include_errors: false, reverse: false
  end
end

class ExampleModel
  include ActiveModel::Model

  attr_accessor :model_field_1, :model_field_2, :model_field_3, :model_field_4,
                :model_field_5, :model_field_6
  validates :model_field_1, format: /\A[^\s]*\Z/, allow_blank: true
  validates :model_field_5, length: { maximum: 1 }
  validates :model_field_6, length: { maximum: 1 }

  def to_model
    :to_model
  end
end

RSpec.describe ExampleForm do

  let(:example_model) { ExampleModel.new }
  let(:value) { double("some value") }

  subject { ExampleForm.new(model: example_model) }

  describe ".fields" do
    it "takes names of fields to define on the form" do
      value_1, value_2 = double("value 1"), double("value 2")
      subject.field_1 = value_1
      subject.field_2 = value_2
      expect(subject.field_1).to eq value_1
      expect(subject.field_2).to eq value_2
    end
  end

  describe "#valid?" do
    it "runs validations and records the errors from form validations" do
      subject.field_1 = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:field_1]).to include "can't be blank"
    end

    it "assigns model errors back to the form for fields" do
      subject.field_1 = "has spaces"
      expect(subject).not_to be_valid
      expect(subject.errors[:field_1]).to include "is invalid"
    end
  end

  describe ".wraps" do
    it "declares an object the form wraps" do
      expect(subject.model).to eq example_model
    end

    it "takes a block to execute for configuration" do
      expect {
        catch(:ran) do
          class NewExampleForm
            include AwesomeForm::Form
            wraps(:slinky) { throw :ran }
          end
          raise "This line should not execute"
        end
      }.not_to raise_error
    end

    it "takes an option to use for naming" do
      expect(subject.to_model).to eq :to_model
    end

    it "requires wrapped models for initialization" do
      expect { described_class.new }.to raise_error ArgumentError
    end

    it "is indifferent to string or symbol keys" do
      expect { described_class.new(model: example_model) }.not_to raise_error
      expect { described_class.new("model" => example_model) }.not_to raise_error
    end

    describe "#assigns" do
      it "configures fields to be assigned to the model on validation" do
        subject = ExampleForm.new(field_1: value, model: example_model)
        subject.valid?
        expect(example_model.model_field_1).to eq value
      end

      it "can use procs for more complex assignments" do
        subject = ExampleForm.new(model: example_model)
        subject.valid?
        expect(example_model.model_field_2).to eq "no-arg proc"
      end

      it "the procs can take the form as an argument" do
        subject = ExampleForm.new(model: example_model)
        subject.valid?
        expect(example_model.model_field_3).to eq "one-arg proc"
      end

      it "the procs can take the form and the wrapped model as arguments" do
        subject = ExampleForm.new(model: example_model)
        subject.valid?
        expect(example_model.model_field_4).to eq "two-arg proc"
      end

      describe "error inclusion" do
        it "can include errors from model fields onto the form" do
          subject.field_5 = "too long"
          subject.valid?
          expect(subject.errors[:field_5]).to eq ["is too long (maximum is 1 characters)"]
        end

        it "automatically includes errors from simple assignments unless overridden" do
          subject.field_1 = "has spaces"
          subject.field_6 = "too long"
          subject.valid?
          expect(subject.errors[:field_1]).to eq ["is invalid"]
          expect(subject.errors[:field_6]).to be_empty
        end
      end

      describe "reverse assignment" do
        let(:example_model) do
          ExampleModel.new(model_field_1: "model val 1",
                           model_field_5: "model val 5",
                           model_field_6: "model val 6")
        end

        subject { ExampleForm.new(model: example_model) }

        it "can assign attributes from the model back to the form with simple assignment" do
          expect(subject.field_6).to eq example_model.model_field_5
        end

        it "can assign attributes from the model back to the form with procs" do
          expect(subject.field_2).to eq "one-arg proc reverse"
          expect(subject.field_3).to eq "two-arg proc reverse"
          expect(subject.field_4).to be_nil
        end

        it "automatically assigns attributes from the model back to the form unless overridden" do
          expect(subject.field_1).to eq example_model.model_field_1
        end
      end
    end
  end

  describe "#save" do
    before do
      allow(example_model).to receive(:save)
      subject.model = example_model
      subject.field_1 = "value"
    end

    it "runs validations" do
      subject.field_1 = nil
      expect(subject.save).to be_falsey
      expect(subject.errors[:field_1]).to include "can't be blank"
    end

    it "saves the wrapped models if validations pass" do
      expect(example_model).to receive(:save)
      subject.save
    end

    it "returns true if all models saved" do
      expect(example_model).to receive(:save).and_return true
      expect(subject.save).to be_truthy
    end

    it "returns false if any model didn't save" do
      expect(example_model).to receive(:save).and_return false
      expect(subject.save).to be_falsey
    end

    it "transacts the save operations in case one fails"
  end

  describe "#save!" do
    before { subject.field_1 = "value" }

    it "raises an exception if any model's save fails" do
      expect(example_model).to receive(:save).and_return false
      subject.model = example_model
      expect {
        subject.save!
      }.to raise_error AwesomeForm::RecordInvalid
    end
  end

  it_should_behave_like "ActiveModel"
end
