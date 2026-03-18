# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sinatra::Health do
  let(:app_class) do
    Class.new(Sinatra::Base) do
      set :host_authorization, permitted_hosts: [] if respond_to?(:host_authorization)
      register OJS::Sinatra::Extension
    end
  end

  def app
    @app ||= app_class
  end

  describe "GET /ojs/health" do
    it "returns 200 with JSON content type" do
      get "/ojs/health"

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include("application/json")
    end

    it "returns healthy status with url" do
      get "/ojs/health"

      body = JSON.parse(last_response.body)
      expect(body["status"]).to eq("healthy")
      expect(body["ojs"]["connected"]).to be true
      expect(body["ojs"]["url"]).to eq("http://localhost:8080")
    end

    it "returns healthy status with custom url" do
      app_class.set :ojs_url, "http://custom-ojs:9090"

      get "/ojs/health"

      body = JSON.parse(last_response.body)
      expect(body["ojs"]["url"]).to eq("http://custom-ojs:9090")
    end

    context "when client raises an error" do
      def app
        @app ||= begin
          failing = OJS::Client.new("http://localhost:8080")
          allow(failing).to receive(:url).and_raise(StandardError, "connection refused")

          Class.new(Sinatra::Base) do
            set :host_authorization, permitted_hosts: [] if respond_to?(:host_authorization)
            register OJS::Sinatra::Extension
            set :ojs_client, failing
          end
        end
      end

      it "returns 503 with unhealthy status" do
        get "/ojs/health"

        expect(last_response.status).to eq(503)
        body = JSON.parse(last_response.body)
        expect(body["status"]).to eq("unhealthy")
        expect(body["error"]).to eq("connection refused")
      end
    end
  end
end
