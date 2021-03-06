module RuoteNATS

  class TimeoutError < StandardError
  end

  # # RuoteNATS::Participant
  #
  class Participant
    include Ruote::LocalParticipant

    DEFAULT_TIMEOUT = 1
    DEFAULT_RETRY   = 0

    # @param [Ruote::Workitem] workitem
    def consume(workitem)
      queue_name = workitem.lookup('params.queue') || 'remote.command'
      message    = MessagePack.pack(workitem.to_h)

      sid = NATS.request(queue_name, message) do |reply|
        RuoteNATS.logger.info do
          "(#{workitem.sid}) request: #{lookup_executor(workitem)} (#{workitem.lookup('params')})"
        end
      end

      timeout = (workitem.lookup('params.timeout') || DEFAULT_TIMEOUT).to_i
      @retry  ||= (workitem.lookup('params.retry') || DEFAULT_RETRY).to_i
      NATS.timeout(sid, timeout) do
        @retry -= 1
        @retry < 0 ? handle_timeout_error(workitem) : handle_retry(workitem)
      end
    rescue
      RuoteNATS.logger.error($!.message)
      raise $!
    end

    def cancel
    end

    private
    def handle_timeout_error(workitem)
      RuoteNATS.logger.error do
        "(#{workitem.sid}) timeout: #{lookup_executor(workitem)} (#{workitem.lookup('params')})"
      end

      error = TimeoutError.new("Request timeout: workitem could not be processed.")

      error_handler = context.error_handler
      error_handler.action_handle('error', workitem.to_h['fei'], error)
    end

    def handle_retry(workitem)
      RuoteNATS.logger.info do
        "(#{workitem.sid}) retry: #{lookup_executor(workitem)} (#{workitem.lookup('params')})"
      end

      consume(workitem)
    end

    def lookup_executor(workitem)
      workitem.lookup('params.executor') || 'RuoteNATS::ShellExecutor'
    end

  end
end
