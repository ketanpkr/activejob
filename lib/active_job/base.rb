require 'active_job/queue_adapter'
require 'active_job/queue_name'
require 'active_job/enqueuing'
require 'active_job/performing'
require 'active_job/logging'

module ActiveJob
  class Base
    extend QueueAdapter
    extend QueueName
    include Enqueuing
    include Performing
    extend Logging
  end
end
