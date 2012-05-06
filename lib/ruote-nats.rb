require 'logger'
require 'msgpack'
require 'nats/client'
require 'ruote'
require 'open3'

require 'ruote-nats/command_receiver'
require 'ruote-nats/participant'
require 'ruote-nats/reply_receiver'
require 'ruote-nats/shell_executor'
require 'ruote-nats/version'

module RuoteNATS
  class << self
    # Get the logger.
    #
    # @return [Logger] logger
    def logger
      @logger ||= Logger.new(STDOUT).tap { |log| log.level = Logger::INFO }
    end

    # Sets the logger.
    #
    # @param [Logger] logger
    def logger=(logger)
      @logger = logger
    end
  end
end
