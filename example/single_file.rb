# -*- mode: ruby; coding: utf-8 -*-

require 'bundler/setup'

require 'ruote'
require 'ruote-nats'

RuoteNATS.logger.level = Logger::DEBUG

NATS.start do
  begin
    pdef = Ruote.define do
      remote_shell :command => '/bin/date', :env => { 'LANG' => 'C' }
    end

    engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))
    engine.register_participant :remote_shell, RuoteNATS::Participant

    RuoteNATS::CommandReceiver.new.start
    RuoteNATS::ReplyReceiver.new(engine).start

    engine.launch(pdef)

    EM.add_timer(1) do
      NATS.stop
    end
  rescue
    Logger.new(STDOUT).error($!.message)
  end
end
