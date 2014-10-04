require_relative "spec_helper"

class ExampleForm
  include AwesomeForm::Form

  fields :field_1, :field_2
  validates :field_1, presence: true
  wraps :model do
    assigns model_field_1: :field_1,
            model_field_2: -> { "no-arg proc"  },
            model_field_3: ->(form) {
              raise unless form.is_a?(ExampleForm)
              "one-arg proc"
            },
            model_field_4: ->(form, model) {
              raise unless form.is_a?(ExampleForm)
              raise unless model.is_a?(ExampleModel)
              "two-arg proc"
            }
  end
end

class ExampleModel
  attr_accessor :model_field_1, :model_field_2, :model_field_3, :model_field_4
end

RSpec.describe ExampleForm do

  let(:model) { ExampleModel.new }
  let(:value) { double("some value") }

  subject { ExampleForm.new }

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
  end

  describe ".wraps" do
    it "declares an object the form wraps" do
      subject.model = model
      expect(subject.model).to eq model
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
      it "configures fields to be assigned to the model on validation" do
        subject = ExampleForm.new(field_1: value, model: model)
        subject.valid?
        expect(model.model_field_1).to eq value
      end

      it "can use procs for more complex assignments" do
        subject = ExampleForm.new(model: model)
        subject.valid?
        expect(model.model_field_2).to eq "no-arg proc"
      end

      it "the procs can take the form as an argument" do
        subject = ExampleForm.new(model: model)
        subject.valid?
        expect(model.model_field_3).to eq "one-arg proc"
      end

      it "the procs can take the form and the wrapped model as arguments" do
        subject = ExampleForm.new(model: model)
        subject.valid?
        expect(model.model_field_4).to eq "two-arg proc"
      end
    end
  end

  describe "#save" do
    before do
      allow(model).to receive(:save)
      subject.model = model
    end

    it "saves the wrapped models" do
      expect(model).to receive(:save)
      subject.save
    end

    it "returns true if all models saved" do
      expect(model).to receive(:save).and_return true
      expect(subject.save).to be_truthy
    end

    it "returns false if any model didn't save" do
      expect(model).to receive(:save).and_return false
      expect(subject.save).to be_falsey
    end
  end

  describe "#save!" do
    it "raises an exception if any model's save fails" do
      expect(model).to receive(:save).and_return false
      subject.model = model
      expect {
        subject.save!
      }.to raise_error AwesomeForm::RecordInvalid
    end
  end
end
