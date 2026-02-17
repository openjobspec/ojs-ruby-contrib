# frozen_string_literal: true

class JobsController < ApplicationController
  def create
    EmailJob.perform_later(
      params[:user_id],
      params[:template] || "default"
    )

    render json: { status: "enqueued" }, status: :accepted
  end
end
