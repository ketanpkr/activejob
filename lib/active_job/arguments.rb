require 'active_model/global_locator'
require 'active_support/core_ext/object/try'

module ActiveJob
  module Arguments
    TYPE_WHITELIST = [ NilClass, Fixnum, Float, String, TrueClass, FalseClass, Hash, Array, Bignum ]

    def self.serialize(args)
      args.collect do |arg|
        if arg.respond_to?(:global_id)
          arg.global_id
        elsif TYPE_WHITELIST.include?(arg.class)
          arg
        else
          raise "Unsupported parameter type: #{arg.class.name}"
        end
      end
    end

    def self.deserialize(args)
      args.collect { |arg| ActiveModel::GlobalLocator.locate(arg) || arg }
    end


    module EnqueueWithSerialization
      def enqueue(*args)
        super *Arguments.serialize(args)
      end

      def enqueue_at(timestamp, *args)
        super timestamp, *Arguments.serialize(args)
      end
    end


    module PerformWithDeserialization
      def perform_with_hooks(*args)
        super *Arguments.deserialize(args)
      end
    end
  end
end
