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
      extend ActiveSupport::Concern

      def self.extended(base)
        base.instance_eval do
          class << self
            alias_method_chain :enqueue,    :serialization
            alias_method_chain :enqueue_at, :serialization
          end
        end
      end

      def enqueue_with_serialization(*args)
        enqueue_without_serialization *Arguments.serialize(args)
      end

      def enqueue_at_with_serialization(timestamp, *args)
        enqueue_at_without_serialization timestamp, *Arguments.serialize(args)
      end
    end


    module PerformWithDeserialization
      extend ActiveSupport::Concern

      included do
        alias_method_chain :perform_with_hooks, :deserialization
      end

      def perform_with_hooks_with_deserialization(*args)
        perform_with_hooks_without_deserialization *Arguments.deserialize(args)
      end
    end
  end
end
