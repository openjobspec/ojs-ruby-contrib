# frozen_string_literal: true

class <%= class_name %>Job < ApplicationJob
  queue_as :<%= queue_name %><%= priority_line %>

  # Optional: include OJS lifecycle callbacks for error classification
  # include OJS::Rails::ActiveJob::Callbacks

  # Retry configuration (uses OJS retry policy under the hood)
  # retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # Discard on non-retryable errors
  # discard_on ActiveJob::DeserializationError

  # @param args [Array] job arguments
  def perform(*args)
    # TODO: Implement <%= class_name %>Job
    raise NotImplementedError, "<%= class_name %>Job#perform not yet implemented"
  end
end
