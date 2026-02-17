# frozen_string_literal: true

class EmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, template)
    puts "Sending #{template} email to user #{user_id}"
  end
end
