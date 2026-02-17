# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sinatra::Extension do
  def app
    @app ||= Class.new(Sinatra::Base) do
      register OJS::Sinatra::Extension

      post "/enqueue" do
        result = enqueue_job("email.send", ["user@example.com"])
        [202, { "Content-Type" => "application/json" }, [result.to_json]]
      end

      get "/client" do
        [200, { "Content-Type" => "application/json" }, [{ url: ojs_client.url }.to_json]]
      end
    end
  end

  describe "POST /enqueue" do
    it "enqueues a job and returns 202" do
      post "/enqueue"
      expect(last_response.status).to eq(202)
    end
  end

  describe "GET /client" do
    it "returns the configured OJS client URL" do
      get "/client"
      expect(last_response.status).to eq(200)

      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("http://localhost:8080")
    end
  end

  describe ".registered" do
    it "sets default ojs_url" do
      expect(app.ojs_url).to eq("http://localhost:8080")
    end
  end
end
