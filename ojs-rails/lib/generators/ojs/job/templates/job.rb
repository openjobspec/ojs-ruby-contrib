# frozen_string_literal: true

class <%= class_name %>Job < ApplicationJob
  queue_as :default

  def perform(*args)
    # TODO: Implement <%= class_name %>Job
  end
end
