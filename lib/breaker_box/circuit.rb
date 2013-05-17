module BreakerBox
  class Circuit

    attr_accessor :failure_callback

    def initialize
      @state = :closed
      @failures = []
      @options = {
        :open_after => 2,
        :within_seconds => 120,
        :timeout => 60 * 60 * 1, # 1 hour
      }
    end

    def run(proc_or_lambda)
      if closed? || half_open?
        begin
          proc_or_lambda.call
          reclose if half_open?
        rescue Exception => e
          fail
          failure_callback.call(e) if failure_callback
        end
      end
    end

    def closed?
      @state == :closed
    end

    def options=(options)
      @options = @options.merge(options)
      @failure_callback = options[:on_failure] if options[:on_failure]
    end

    protected

    def fail
      @failures << Time.now.utc

      if pertinent_failures.count == @options[:open_after]
        @state = :open
      end
    end

    def half_open?
      @state == :open && timeout_expired?
    end

    def pertinent_failures
      @failures.select {|f| Time.now.utc - @options[:within_seconds] < f}
    end

    def timeout_expired?
      failed_at + @options[:timeout] < Time.now.utc
    end

    def failed_at
      @failures.last
    end

    def reclose
      @state = :closed
      @failures = []
    end
  end
end
