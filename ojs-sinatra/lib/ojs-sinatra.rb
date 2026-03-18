# frozen_string_literal: true

require "json"
require "ojs"
require "ojs/sinatra/extension"
require "ojs/sinatra/helpers"
require "ojs/sinatra/worker"
require "ojs/sinatra/health"
require "ojs/sinatra/tasks"

module OJS
  module Sinatra
    class Error < StandardError; end
  end
end

