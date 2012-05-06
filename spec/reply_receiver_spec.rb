require 'spec_helper'

module RuoteNATS

  describe ReplyReceiver do
    around :each do |example|
      NATS.start(autostart: true) { example.run }
    end

    let(:engine) { MockEngine.new }
    let(:receiver) { ReplyReceiver.new(engine) }
    let(:message) { MessagePack.pack(workitem.to_h) }

    describe '#start' do
      context 'success' do
        let(:workitem) do
          Ruote::Workitem.new("fields"           =>
                                  { "params"        =>
                                        { "executor" => "ReplyReceiverSpec" },
                                    "dispatched_at" => "2000-01-01 11:11:11.111111 UTC",
                                    "__result__"    => "success" },
                              "fei"              =>
                                  { "engine_id" => "engine",
                                    "wfid"      => "20000101-abcdefg",
                                    "subid"     => "abcdefghijklmnopqrstu",
                                    "expid"     => "0_0" },
                              "participant_name" => "shell")
        end

        it 'replies to engine' do
          receiver.start
          NATS.publish('remote.command.reply', message)

          EM.add_timer(1) do
            fail "#reply_to_engine must be called"
          end
        end
      end

      context 'failure' do
        let(:workitem) do
          Ruote::Workitem.new("fields"           =>
                                  { "params"        =>
                                        { "executor" => "ReplyReceiverSpec" },
                                    "dispatched_at" => "2000-01-01 11:11:11.111111 UTC",
                                    "__result__"    => "failure" },
                              "fei"              =>
                                  { "engine_id" => "engine",
                                    "wfid"      => "20000101-abcdefg",
                                    "subid"     => "abcdefghijklmnopqrstu",
                                    "expid"     => "0_0" },
                              "participant_name" => "shell")
        end
        it 'replies to engine' do
          handler = double.as_null_object
          engine.stub_chain(:context, :error_handler => handler)

          receiver.start
          NATS.publish('remote.command.reply', message)

          EM.add_timer(1) do
            fail "#handle_error must be called"
            NATS.stop
          end
        end
      end

    end
  end
end
