require 'active_support/concern'
require 'active_support/core_ext/module/aliasing'

module RailsLegacyMapper
  module RouteSetExtensions #:nodoc:
    extend ActiveSupport::Concern

    CONTROLLER_REGEXP = /[_a-zA-Z0-9]+/

    included do
      attr_accessor :controller_namespaces
      alias_method_chain :initialize, :legacy_mapper
      alias_method_chain :eval_block, :legacy_mapper
    end

    module InstanceMethods #:nodoc:
      def initialize_with_legacy_mapper(request_class = ActionDispatch::Request)
        initialize_without_legacy_mapper
        self.controller_namespaces = Set.new
      end

      def controller_constraints
        @controller_constraints ||= begin
          namespaces = controller_namespaces + in_memory_controller_namespaces
          source = namespaces.map { |ns| "#{Regexp.escape(ns)}/#{CONTROLLER_REGEXP.source}" }
          source << CONTROLLER_REGEXP.source
          Regexp.compile(source.sort.reverse.join('|'))
        end
      end

      def in_memory_controller_namespaces
        namespaces = Set.new
        ActionController::Base.descendants.each do |klass|
          next if klass.anonymous?
          namespaces << klass.name.underscore.split('/')[0...-1].join('/')
        end
        namespaces.delete('')
        namespaces
      end

      def eval_block_with_legacy_mapper(block)
        mapper = ActionDispatch::Routing::Mapper.new(self)
        if block.arity == 1
          mapper.instance_exec(RailsLegacyMapper::Mapper.new(self), &block)
        elsif default_scope
          mapper.with_default_scope(default_scope, &block)
        else
          mapper.instance_exec(&block)
        end
      end
    end
  end
end