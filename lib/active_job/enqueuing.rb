require 'active_job/arguments'
require 'active_job/logging'

module ActiveJob
  module Enqueuing
    def self.extended(base)
      base.extend Logging::EnqueueWithLogging
      base.extend Arguments::EnqueueWithSerialization
    end
    
    # Push a job onto the queue.  The arguments must be legal JSON types
    # (string, int, float, nil, true, false, hash or array) or
    # ActiveModel::GlobalIdentication instances.  Arbitrary Ruby objects
    # are not supported.
    #
    # The return value is adapter-specific and may change in a future
    # ActiveJob release.
    def enqueue(*args)
      queue_adapter.enqueue self, *args
    end

    # Enqueue a job to be performed at +interval+ from now.
    #
    #   enqueue_in(1.week, "mike")
    #
    # Returns truthy if a job was scheduled.
    def enqueue_in(interval, *args)
      enqueue_at interval.from_now, *args
    end

    # Enqueue a job to be performed at an explicit point in time.
    #
    #   enqueue_at(Date.tomorrow.midnight, "mike")
    #
    # Returns truthy if a job was scheduled.
    def enqueue_at(timestamp, *args)
      queue_adapter.enqueue_at self, timestamp.to_f, *args
    end
  end
end
