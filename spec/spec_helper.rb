# -*- mode:ruby; coding: utf-8 -*-

require 'eventmachine'
require 'simplecov'
SimpleCov.start { add_filter 'spec' }

require 'ruote-nats'

RSpec.configure do |config|
  config.before(:all) do
    RuoteNATS.logger.level = Logger::DEBUG
  end

  config.after(:all) do
    begin
      pid = IO.read('/tmp/nats-server.pid')
      `kill -TERM #{pid}`
    rescue Errno::ENOENT
    end
  end
end


module RuoteNATS
  class MockErrorHandler
    def action_handle(action, fei, exception)
      NATS.stop
    end
  end

  class MockContext
    def error_handler
      MockErrorHandler.new
    end
  end

  class MockEngine
    def reply_to_engine(workitem)
      NATS.stop
    end

    def context
      MockContext.new
    end
  end
end
