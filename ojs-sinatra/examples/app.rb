# frozen_string_literal: true

require "sinatra"
require "json"
require "ojs-sinatra"

register OJS::Sinatra::Extension

configure do
  set :ojs_url, ENV.fetch("OJS_URL", "http://localhost:8080")
end

post "/enqueue" do
  data = JSON.parse(request.body.read)
  enqueue_job(data["type"], data["args"])

  status 202
  content_type :json
  { status: "enqueued", type: data["type"] }.to_json
end

get "/health" do
  content_type :json
  { status: "ok" }.to_json
end
