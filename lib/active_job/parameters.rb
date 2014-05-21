require 'active_model/global_locator'
require 'active_support/core_ext/object/try'

module ActiveJob
  module Parameters
    TYPE_WHITELIST = [ NilClass, Fixnum, Float, String, TrueClass, FalseClass, Hash, Array, Bignum ]

    def self.serialize(params)
      params.collect do |param|
        if param.respond_to?(:global_id)
          param.global_id
        elsif TYPE_WHITELIST.include?(param.class)
          param
        else
          raise "Unsupported parameter type: #{param.class.name}"
        end
      end
    end

    def self.deserialize(params)
      params.collect { |param| ActiveModel::GlobalLocator.locate(param) || param }
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
        enqueue_without_serialization *Parameters.serialize(args)
      end

      def enqueue_at_with_serialization(timestamp, *args)
        enqueue_at_without_serialization timestamp, *Parameters.serialize(args)
      end
    end


    module PerformWithDeserialization
      extend ActiveSupport::Concern

      included do
        alias_method_chain :perform_with_hooks, :deserialization
      end

      def perform_with_hooks_with_deserialization(*args)
        perform_with_hooks_without_deserialization *Parameters.deserialize(args)
      end
    end
  end
end
