# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Rails::ActiveJob::Callbacks do
  # Minimal test harness — we test the module methods directly
  # since full ActiveJob integration requires Rails boot.

  let(:callback_module) { described_class }

  describe "module definition" do
    it "is defined as a module" do
      expect(callback_module).to be_a(Module)
    end
  end

  describe "error classification" do
    # Create a test class that includes the private methods for testing
    let(:test_instance) do
      klass = Class.new do
        include OJS::Rails::ActiveJob::Callbacks

        # Expose private methods for testing
        public :ojs_error_code, :ojs_retryable?
      end
      klass.new
    end

    describe "#ojs_error_code" do
      it "classifies ArgumentError as invalid_arguments" do
        expect(test_instance.ojs_error_code(ArgumentError.new("bad"))).to eq("invalid_arguments")
      end

      it "classifies TypeError as invalid_arguments" do
        expect(test_instance.ojs_error_code(TypeError.new("wrong type"))).to eq("invalid_arguments")
      end

      it "classifies OJS::ValidationError as validation_error" do
        expect(test_instance.ojs_error_code(OJS::ValidationError.new("invalid"))).to eq("validation_error")
      end

      it "classifies OJS::ConflictError as duplicate" do
        expect(test_instance.ojs_error_code(OJS::ConflictError.new("dup"))).to eq("duplicate")
      end

      it "classifies OJS::TimeoutError as timeout" do
        expect(test_instance.ojs_error_code(OJS::TimeoutError.new("slow"))).to eq("timeout")
      end

      it "classifies OJS::ConnectionError as connection_error" do
        expect(test_instance.ojs_error_code(OJS::ConnectionError.new("refused"))).to eq("connection_error")
      end

      it "classifies unknown errors as unknown_error" do
        expect(test_instance.ojs_error_code(RuntimeError.new("oops"))).to eq("unknown_error")
      end
    end

    describe "#ojs_retryable?" do
      it "marks timeout errors as retryable" do
        expect(test_instance.ojs_retryable?(OJS::TimeoutError.new)).to be true
      end

      it "marks connection errors as retryable" do
        expect(test_instance.ojs_retryable?(OJS::ConnectionError.new)).to be true
      end

      it "marks ArgumentError as non-retryable" do
        expect(test_instance.ojs_retryable?(ArgumentError.new)).to be false
      end

      it "marks TypeError as non-retryable" do
        expect(test_instance.ojs_retryable?(TypeError.new)).to be false
      end

      it "marks unknown errors as non-retryable" do
        expect(test_instance.ojs_retryable?(RuntimeError.new)).to be false
      end

      it "checks retryable? method on OJS errors" do
        error = OJS::ConnectionError.new("conn failed")
        expect(test_instance.ojs_retryable?(error)).to be true
      end
    end
  end
end
