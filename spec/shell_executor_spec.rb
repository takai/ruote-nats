require 'spec_helper'

module RuoteNATS
  describe ShellExecutor do
    describe '#execute' do
      subject { ShellExecutor.new.execute(workitem) }

      context 'with command and env fields' do
        let(:workitem) do
          Ruote::Workitem.new("fields"           =>
                                  { "params"        =>
                                        { "command" => "ruby -e 'print ENV[\"LANG\"]'",
                                          "env"     => {
                                              "LANG" => "ja_JP.UTF-8" },
                                          "ref"     => "shell" },
                                    "dispatched_at" => "2000-01-01 11:11:11.111111 UTC" },
                              "fei"              =>
                                  { "engine_id" => "engine",
                                    "wfid"      => "20000101-abcdefg",
                                    "subid"     => "abcdefghijklmnopqrstu",
                                    "expid"     => "0_0" },
                              "participant_name" => "shell")
        end
        it { should include(out: "ja_JP.UTF-8") }
      end

      context 'without command fields' do
        let(:workitem) do
          Ruote::Workitem.new("fields"           =>
                                  { "params"        =>
                                        { "ref" => "shell" },
                                    "dispatched_at" => "2000-01-01 11:11:11.111111 UTC" },
                              "fei"              =>
                                  { "engine_id" => "engine",
                                    "wfid"      => "20000101-abcdefg",
                                    "subid"     => "abcdefghijklmnopqrstu",
                                    "expid"     => "0_0" },
                              "participant_name" => "send_command")
        end
        it { expect{ subject }.to raise_error(RuntimeError, 'command is not specified, check your process definition') }
      end
    end
  end
end
