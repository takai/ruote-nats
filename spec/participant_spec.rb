require 'spec_helper'

module RuoteNATS
  describe Participant do
    around :each do |example|
      NATS.start(autostart: true) { example.run }
    end

    let(:workitem) do
      Ruote::Workitem.new("fields"           =>
                              { "params"        =>
                                    { "command" => "/bin/date",
                                      "env"     => {
                                          "LANG" => "C" },
                                      "ref"     => "shell" },
                                "dispatched_at" => "2000-01-01 11:11:11.111111 UTC" },
                          "fei"              =>
                              { "engine_id" => "engine",
                                "wfid"      => "20000101-abcdefg",
                                "subid"     => "abcdefghijklmnopqrstu",
                                "expid"     => "0_0" },
                          "participant_name" => "shell")
    end

    describe '#consume' do
      context 'send successfully' do
        it 'sends command message' do
          sid = NATS.subscribe('remote.command', queue: 'remote.command', max: 1) do |message, reply|
            unpacked = MessagePack.unpack(message)
            unpacked.should eq workitem.to_h

            NATS.publish(reply, 'ACCEPT') do
              NATS.stop
            end
          end
          NATS.timeout(sid, 1, expected: 1) do
            NATS.stop
            fail "command message is not sent"
          end

          subject.consume(workitem)
        end
      end
      context 'error with timeout' do
        before { subject.context = MockContext.new }

        it 'sends command message' do
          EM.add_timer(2) do
            NATS.stop
            fail "#handle_error must be called"
          end
          subject.consume(workitem)
        end

        it 'retries with :retry options' do
          EM.add_timer(3) do
            NATS.stop
            fail "#handle_error must be called"
          end
          workitem.params['retry'] = 1
          subject.consume(workitem)
        end
      end
    end
  end
end
