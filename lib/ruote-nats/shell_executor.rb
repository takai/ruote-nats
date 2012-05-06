module RuoteNATS
  class ShellExecutor

    # Execute shell command
    #
    # @param [Ruote::Workitem] workitem
    # @return [Hash] the result of command execution
    def execute(workitem)
      if workitem.lookup('params.command')
        out, status = invoke(workitem)

        if status.success?
          { out: out, status: status.exitstatus, finished_at: Ruote.now_to_utc_s }
        else
          raise "out: #{out}, status: #{status.exitstatus}, finished_at: #{Ruote.now_to_utc_s}"
        end
      else
        workitem.result = 'failure'

        message = 'command is not specified, check your process definition'
        RuoteNATS.logger.error do
          "(#{workitem.sid}) shell: #{message}"
        end
        raise message
      end
    end

    private
    def invoke(workitem)
      params  = workitem.lookup('params')
      env     = params['env'] || { }
      command = params['command']

      RuoteNATS.logger.info do
        message = "(#{workitem.sid}) shell: `#{command}`"
        message << " with env #{env.inspect}" if env
        message
      end

      out, status = Open3.capture2e(env, command)

      RuoteNATS.logger.info do
        "(#{workitem.sid}) shell: `#{command}` returns #{status.exitstatus}"
      end
      if RuoteNATS.logger.debug?
        out.each_line do |line|
          RuoteNATS.logger.debug "(#{workitem.sid}) shell:   #{line.chomp}"
        end
      end

      return out, status
    end

  end
end
