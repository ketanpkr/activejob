require 'active_job/parameters'
require 'active_job/logging'

module ActiveJob
  module Performing
    extend ActiveSupport::Concern
    
    included do
      include Parameters::PerformWithDeserialization
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
