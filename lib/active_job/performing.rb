require 'active_job/arguments'
require 'active_job/logging'

module ActiveJob
  module Performing
    extend ActiveSupport::Concern
    
    included do
      include Arguments::PerformWithDeserialization
      include Logging::PerformWithLogging
    end

    def perform_with_hooks(*args)
      perform(*args)
    end

    def perform(*)
      raise NotImplementedError
    end
  end
end
