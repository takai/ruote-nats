module RuoteNATS
  class CommandReceiver

    # Starts to subscribe command queue.
    #
    # @param [String] queue_name
    def start(queue_name = 'remote.command')
      NATS.subscribe(queue_name, queue: queue_name, max: 1) do |message, reply|
        NATS.publish(reply, 'ACCEPT') do
          unpacked = MessagePack.unpack(message)
          workitem = Ruote::Workitem.new(unpacked)

          RuoteNATS.logger.info do
            "(#{workitem.sid}) receive command: #{lookup_executor(workitem)} (#{workitem.lookup('params')})"
          end

          dispatch(workitem)
          publish_reply(workitem)
        end
      end
    end

    private
    def dispatch(workitem)
      executor = lookup_executor(workitem)
      results  = constantize(executor).new.execute(workitem)
    rescue
      workitem.result = 'error'
      results = { message: $!.message, backtrace: $!.backtrace }
    ensure
      store_results(workitem, results)
    end

    def lookup_executor(workitem)
      workitem.lookup('params.executor') || 'RuoteNATS::ShellExecutor'
    end

    def constantize(executor_name)
      names = executor_name.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end

    def store_results(workitem, results)
      params = workitem.lookup('params')

      workitem.set_field('results', Hash.new) unless workitem.lookup('results')
      workitem.set_field("results.#{workitem.sid}", params.merge(results))
    end

    def publish_reply(workitem)
      queue_name = workitem.lookup('reply_to') || 'remote.command.reply'

      packed = MessagePack.pack(workitem.to_h)
      NATS.publish(queue_name, packed) do
        RuoteNATS.logger.info do
          results = workitem.lookup("results.#{workitem.sid}")
          "(#{workitem.sid}) reply: #{lookup_executor(workitem)} (#{results})"
        end
      end
    end
  end

end
