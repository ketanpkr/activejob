require 'active_support/core_ext/string/filters'

module ActiveJob
  module Logging
    mattr_accessor(:logger) { ActiveSupport::Logger.new(STDOUT) }

    module EnqueueWithLogging
      def enqueue(*args)
        ActiveSupport::Notifications.instrument "enqueue.active_job", adapter: queue_adapter, job: self, args: args
        super
      end

      def enqueue_at(timestamp, *args)
        ActiveSupport::Notifications.instrument "enqueue_at.active_job", adapter: queue_adapter, job: self, args: args, timestamp: timestamp
        super
      end
    end

    module PerformWithLogging
      def perform_with_hooks(*args)
        ActiveSupport::Notifications.instrument "perform.active_job", adapter: self.class.queue_adapter, job: self.class, args: args
        super
      end
    end

    class LogSubscriber < ActiveSupport::LogSubscriber
      attach_to :active_job

      def enqueue(event)
        info "Enqueued #{event.payload[:job].name} to #{queue_name(event)}" + args_info(event)
      end

      def enqueue_at(event)
        info "Enqueued #{event.payload[:job].name} to #{queue_name(event)} at #{enqueued_at(event)}" + args_info(event)
      end

      def perform(event)
        info "Performed #{event.payload[:job].name} from #{queue_name(event)}" + args_info(event)
      end

      private
        def queue_name(event)
          event.payload[:adapter].name.demodulize.remove('Adapter')
        end

        def args_info(event)
          event.payload[:args].any? ? ": #{event.payload[:args].inspect}" : ""
        end

        def enqueued_at(event)
          Time.at(event.payload[:timestamp]).utc
        end

        def logger
          ActiveJob::Base.logger
        end
    end
  end
end
