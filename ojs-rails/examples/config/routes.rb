# frozen_string_literal: true

Rails.application.routes.draw do
  resources :jobs, only: [:create]
end
