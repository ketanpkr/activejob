require 'active_support/core_ext/string/filters'

module ActiveJob
  module Logging
    mattr_accessor(:logger) { ActiveSupport::Logger.new(STDOUT) }

    module EnqueueWithLogging
      extend ActiveSupport::Concern

      def self.extended(base)
        base.instance_eval do
          class << self
            alias_method_chain :enqueue,    :logging
            alias_method_chain :enqueue_at, :logging
          end
        end
      end

      def enqueue_with_logging(*args)
        ActiveSupport::Notifications.instrument "enqueue.active_job", adapter: queue_adapter, job: self, args: args
        enqueue_without_logging *args
      end

      def enqueue_at_with_logging(timestamp, *args)
        ActiveSupport::Notifications.instrument "enqueue_at.active_job", adapter: queue_adapter, job: self, args: args, timestamp: timestamp
        enqueue_at_without_logging timestamp, *args
      end
    end

    module PerformWithLogging
      extend ActiveSupport::Concern

      included do
        alias_method_chain :perform_with_hooks, :logging
      end

      def perform_with_hooks_with_logging(*args)
        ActiveSupport::Notifications.instrument "perform.active_job", adapter: self.class.queue_adapter, job: self.class, args: args
        perform_with_hooks_without_logging *args
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
