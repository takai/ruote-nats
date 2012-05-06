module RuoteNATS
  class ReplyReceiver

    # @param [Ruote::Engine] engine
    def initialize(engine)
      @engine = engine
    end

    # Start to subscribe reply queue.
    #
    # @param [String] queue name
    def start(queue_name = 'remote.command.reply')
      NATS.subscribe(queue_name) do |message, reply|
        unpacked = MessagePack.unpack(message)
        workitem = Ruote::Workitem.new(unpacked)

        RuoteNATS.logger.info do
          executor = workitem.lookup('params.executor') || 'RuoteNATS::ShellExecutor'
          result   = workitem.lookup("results.#{workitem.sid}")

          "(#{workitem.sid}) receive reply: #{executor} #{workitem.result} (#{result})"
        end

        if workitem.result == 'success'
          @engine.reply_to_engine(workitem)
        else
          handle_error(workitem)
        end
      end
    end

    private
    def handle_error(workitem)
      message   = workitem.lookup("results.#{workitem.sid}.message")
      backtrace = workitem.lookup("results.#{workitem.sid}.backtrace")

      error = RuntimeError.new(message)
      error.set_backtrace(backtrace)

      error_handler = @engine.context.error_handler
      error_handler.action_handle('error', workitem.to_h['fei'], error)
    end
  end
end
