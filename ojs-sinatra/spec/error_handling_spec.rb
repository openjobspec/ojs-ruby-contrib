# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS::Sinatra error handling" do
  describe OJS::Sinatra::Error do
    it "is a subclass of StandardError" do
      expect(OJS::Sinatra::Error).to be < StandardError
    end

    it "can be raised with a message" do
      expect {
        raise OJS::Sinatra::Error, "connection failed"
      }.to raise_error(OJS::Sinatra::Error, "connection failed")
    end

    it "can be rescued as StandardError" do
      expect {
        begin
          raise OJS::Sinatra::Error, "test"
        rescue StandardError
          nil
        end
      }.not_to raise_error
    end
  end

  describe "route error handling" do
    let(:failing_client) do
      client = OJS::Client.new("http://localhost:8080")
      allow(client).to receive(:enqueue).and_raise(StandardError, "connection refused")
      client
    end

    def app
      @app ||= begin
        fc = failing_client
        Class.new(Sinatra::Base) do
          register OJS::Sinatra::Extension
          set :host_authorization, permitted_hosts: [] if respond_to?(:host_authorization)
          set :ojs_client, fc

          post "/enqueue-fail" do
            begin
              enqueue_job("email.send", ["user@test.com"])
              [202, {}, ["ok"]]
            rescue StandardError => e
              [503, { "Content-Type" => "application/json" }, [{ error: e.message }.to_json]]
            end
          end
        end
      end
    end

    it "allows routes to handle enqueue errors gracefully" do
      post "/enqueue-fail"
      expect(last_response.status).to eq(503)
      body = JSON.parse(last_response.body)
      expect(body["error"]).to eq("connection refused")
    end
  end
end
