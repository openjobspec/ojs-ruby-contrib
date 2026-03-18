# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sidekiq::EventBridge do
  let(:mock_client) { instance_double(OJS::Client) }

  before { OJS::Sidekiq.client = mock_client }

  describe "#initialize" do
    it "creates a bridge with module-level client" do
      bridge = described_class.new
      expect(bridge).to be_a(described_class)
    end

    it "accepts an explicit client" do
      bridge = described_class.new(client: mock_client)
      expect(bridge).to be_a(described_class)
    end

    it "starts with no listeners" do
      bridge = described_class.new
      expect(bridge.registered_events).to be_empty
    end
  end

  describe "#on" do
    let(:bridge) { described_class.new }

    it "registers a listener for a valid event" do
      bridge.on(:job_started) { |payload| payload }
      expect(bridge.listener_count(:job_started)).to eq(1)
    end

    it "returns self for chaining" do
      result = bridge.on(:job_started) { |payload| payload }
      expect(result).to eq(bridge)
    end

    it "raises ArgumentError for unknown event" do
      expect {
        bridge.on(:unknown_event) { |payload| payload }
      }.to raise_error(ArgumentError, /Unknown event: unknown_event/)
    end

    it "accepts string event names" do
      bridge.on("job_completed") { |payload| payload }
      expect(bridge.listener_count(:job_completed)).to eq(1)
    end

    it "allows multiple listeners for the same event" do
      bridge.on(:job_started) { |p| "first" }
      bridge.on(:job_started) { |p| "second" }
      expect(bridge.listener_count(:job_started)).to eq(2)
    end

    OJS::Sidekiq::EventBridge::EVENTS.each do |event|
      it "accepts the #{event} event" do
        expect { bridge.on(event) { |p| p } }.not_to raise_error
      end
    end
  end

  describe "#emit" do
    let(:bridge) { described_class.new }

    it "calls registered listeners with enriched payload" do
      received = nil
      bridge.on(:job_completed) { |payload| received = payload }

      bridge.emit(:job_completed, job_id: "abc-123")

      expect(received[:event]).to eq(:job_completed)
      expect(received[:job_id]).to eq("abc-123")
      expect(received[:timestamp]).to be_a(String)
    end

    it "calls multiple listeners in order" do
      results = []
      bridge.on(:job_started) { |_| results << "first" }
      bridge.on(:job_started) { |_| results << "second" }

      bridge.emit(:job_started)

      expect(results).to eq(%w[first second])
    end

    it "returns results from all listeners" do
      bridge.on(:job_completed) { |_| "result_a" }
      bridge.on(:job_completed) { |_| "result_b" }

      results = bridge.emit(:job_completed)
      expect(results).to eq(%w[result_a result_b])
    end

    it "returns empty array when no listeners registered" do
      results = bridge.emit(:job_started)
      expect(results).to eq([])
    end

    it "enriches payload with event name and timestamp" do
      received = nil
      bridge.on(:worker_started) { |payload| received = payload }

      freeze_time = Time.utc(2026, 1, 15, 12, 0, 0)
      allow(Time).to receive(:now).and_return(freeze_time)

      bridge.emit(:worker_started, pid: 12345)

      expect(received[:event]).to eq(:worker_started)
      expect(received[:timestamp]).to eq("2026-01-15T12:00:00Z")
      expect(received[:pid]).to eq(12345)
    end

    it "accepts string event names" do
      received = nil
      bridge.on(:job_failed) { |payload| received = payload }

      bridge.emit("job_failed", error: "timeout")
      expect(received[:error]).to eq("timeout")
    end
  end

  describe "#registered_events" do
    let(:bridge) { described_class.new }

    it "returns empty array with no listeners" do
      expect(bridge.registered_events).to eq([])
    end

    it "returns events that have listeners" do
      bridge.on(:job_started) { |p| p }
      bridge.on(:job_completed) { |p| p }

      expect(bridge.registered_events).to contain_exactly(:job_started, :job_completed)
    end

    it "does not include events without listeners" do
      bridge.on(:job_started) { |p| p }
      expect(bridge.registered_events).not_to include(:job_completed)
    end
  end

  describe "#listener_count" do
    let(:bridge) { described_class.new }

    it "returns 0 for events with no listeners" do
      expect(bridge.listener_count(:job_started)).to eq(0)
    end

    it "returns correct count for events with listeners" do
      bridge.on(:job_started) { |p| p }
      bridge.on(:job_started) { |p| p }
      bridge.on(:job_completed) { |p| p }

      expect(bridge.listener_count(:job_started)).to eq(2)
      expect(bridge.listener_count(:job_completed)).to eq(1)
    end
  end

  describe "#stats" do
    let(:bridge) { described_class.new }

    it "returns empty hash with no listeners" do
      expect(bridge.stats).to eq({})
    end

    it "returns counts for events with listeners" do
      bridge.on(:job_started) { |p| p }
      bridge.on(:job_started) { |p| p }
      bridge.on(:job_completed) { |p| p }

      stats = bridge.stats
      expect(stats[:job_started]).to eq(2)
      expect(stats[:job_completed]).to eq(1)
      expect(stats).not_to have_key(:job_failed)
    end
  end

  describe "::EVENTS" do
    it "contains the expected lifecycle events" do
      expect(described_class::EVENTS).to contain_exactly(
        :job_started, :job_completed, :job_failed, :job_retrying,
        :worker_started, :worker_stopped, :worker_heartbeat
      )
    end

    it "is frozen" do
      expect(described_class::EVENTS).to be_frozen
    end
  end
end
