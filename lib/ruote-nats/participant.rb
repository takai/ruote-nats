module RuoteNATS

  class TimeoutError < StandardError
  end

  # # RuoteNATS::Participant
  #
  class Participant
    include Ruote::LocalParticipant

    DEFALUT_TIMEOUT = 1

    # @param [Ruote::Workitem] workitem
    def consume(workitem)
      queue_name = workitem.lookup('params.queue') || 'remote.command'
      message    = MessagePack.pack(workitem.to_h)

      sid = NATS.request(queue_name, message) do |reply|
        RuoteNATS.logger.info do
          executor = workitem.lookup('params.executor') || 'RuoteNATS::ShellExecutor'
          "(#{workitem.sid}) request: #{executor} (#{workitem.lookup('params')})"
        end
      end

      timeout = (workitem.lookup('params.timeout') || DEFALUT_TIMEOUT).to_i
      NATS.timeout(sid, timeout) do
        handle_error(workitem)
      end
    rescue
      RuoteNATS.logger.error($!.message)
      raise $!
    end

    def cancel
    end

    private
    def handle_error(workitem)
      executor = workitem.lookup('params.executor') || 'RuoteNATS::ShellExecutor'
      RuoteNATS.logger.error do
        "(#{workitem.sid}) timeout: #{executor} (#{workitem.lookup('params')})"
      end

      error = TimeoutError.new("Request timeout: workitem could not be processed.")

      error_handler = context.error_handler
      error_handler.action_handle('error', workitem.to_h['fei'], error)
    end
  end
end
