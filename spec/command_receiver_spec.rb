require 'spec_helper'

module RuoteNATS

  class NoopExecutor
    def execute(workitem)
      { noop: true }
    end
  end

  describe CommandReceiver do
    let(:dispatcher) { CommandReceiver.new }
    let(:workitem) do
      Ruote::Workitem.new("fields"           =>
                              { "params"        =>
                                    { "command"  => "/bin/date",
                                      "env"      => {
                                          "LANG" => "C" },
                                      "ref"      => "noop",
                                      "executor" => "RuoteNATS::NoopExecutor" },
                                "dispatched_at" => "2000-01-01 11:11:11.111111 UTC" },
                          "fei"              =>
                              { "engine_id" => "engine",
                                "wfid"      => "20000101-abcdefg",
                                "subid"     => "abcdefghijklmnopqrstu",
                                "expid"     => "0_0" },
                          "participant_name" => "noop")
    end

    around :each do |example|
      NATS.start(autostart: true) { example.run }
    end

    describe '#start' do
      context do
        it 'starts to subscribe queue' do
          sid = NATS.subscribe('remote.command.reply') do |message|
            unpacked = MessagePack.unpack(message)
            workitem = Ruote::Workitem.new(unpacked)
            workitem.lookup("results.#{workitem.sid}").should include("noop" => true)

            NATS.stop
          end
          NATS.timeout(sid, 1, expected: 1) do
            NATS.stop
            fail "reply message is not sent"
          end

          subject.start
          message = MessagePack.pack(workitem.to_h)
          NATS.request('remote.command', message) do |reply|
          end
        end
      end
    end
  end
end
