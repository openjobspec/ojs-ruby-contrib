# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sinatra::Helpers do
  let(:app_class) do
    Class.new(Sinatra::Base) do
      register OJS::Sinatra::Extension
      set :host_authorization, permitted_hosts: [] if respond_to?(:host_authorization)
    end
  end

  def app
    @app ||= app_class
  end

  describe "#ojs_client" do
    it "returns an OJS::Client instance" do
      app_class.class_eval do
        get "/client-check" do
          [200, { "Content-Type" => "application/json" }, [{ class: ojs_client.class.name }.to_json]]
        end
      end

      get "/client-check"
      body = JSON.parse(last_response.body)
      expect(body["class"]).to eq("OJS::Client")
    end

    it "uses the configured ojs_url" do
      app_class.set :ojs_url, "http://custom:9090"

      app_class.class_eval do
        get "/custom-url" do
          [200, { "Content-Type" => "application/json" }, [{ url: ojs_client.url }.to_json]]
        end
      end

      get "/custom-url"
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("http://custom:9090")
    end

    it "reuses the same client instance across requests" do
      app_class.class_eval do
        get "/client-id" do
          [200, { "Content-Type" => "application/json" }, [{ id: ojs_client.object_id }.to_json]]
        end
      end

      get "/client-id"
      first_id = JSON.parse(last_response.body)["id"]

      get "/client-id"
      second_id = JSON.parse(last_response.body)["id"]

      expect(first_id).to eq(second_id)
    end

    it "allows setting a pre-configured client" do
      custom_client = OJS::Client.new("http://preconfigured:7070")
      app_class.set :ojs_client, custom_client

      app_class.class_eval do
        get "/preconfigured" do
          [200, { "Content-Type" => "application/json" }, [{ url: ojs_client.url }.to_json]]
        end
      end

      get "/preconfigured"
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("http://preconfigured:7070")
    end
  end

  describe "#enqueue_job" do
    it "enqueues with default queue" do
      app_class.class_eval do
        post "/enqueue-default" do
          result = enqueue_job("email.send", ["user@test.com"])
          [202, { "Content-Type" => "application/json" }, [result.to_json]]
        end
      end

      post "/enqueue-default"
      body = JSON.parse(last_response.body)
      expect(body["type"]).to eq("email.send")
      expect(body["args"]).to eq(["user@test.com"])
      expect(body["queue"]).to eq("default")
    end

    it "enqueues with a custom queue" do
      app_class.class_eval do
        post "/enqueue-custom" do
          result = enqueue_job("report.generate", [42], queue: "reports")
          [202, { "Content-Type" => "application/json" }, [result.to_json]]
        end
      end

      post "/enqueue-custom"
      body = JSON.parse(last_response.body)
      expect(body["queue"]).to eq("reports")
    end

    it "passes additional options through" do
      app_class.class_eval do
        post "/enqueue-options" do
          result = enqueue_job("email.send", ["user@test.com"], queue: "mailers", priority: 10)
          [202, { "Content-Type" => "application/json" }, [result.to_json]]
        end
      end

      post "/enqueue-options"
      body = JSON.parse(last_response.body)
      expect(body["priority"]).to eq(10)
      expect(body["queue"]).to eq("mailers")
    end

    it "handles empty args" do
      app_class.class_eval do
        post "/enqueue-empty" do
          result = enqueue_job("cleanup.run", [])
          [202, { "Content-Type" => "application/json" }, [result.to_json]]
        end
      end

      post "/enqueue-empty"
      body = JSON.parse(last_response.body)
      expect(body["type"]).to eq("cleanup.run")
      expect(body["args"]).to eq([])
    end
  end
end
