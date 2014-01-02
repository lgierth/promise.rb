# encoding: utf-8

class Promise
  module Attribute
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def initialize(*args)
      super(*args)
      promises.map { |name| send(name) }
    end

    private

    def promises
      self.class.send(:promises)
    end

    def get_or_set_promise(ivar)
      if instance_variable_defined?(ivar)
        instance_variable_get(ivar)
      else
        instance_variable_set(ivar, Hatetepe::Promise.new)
      end
    end

    module ClassMethods
      private

      def promises
        @promises ||= []
      end

      def promise(name)
        promises << name
        define_promise(name, "@#{name}")
      end

      def define_promise(name, ivar)
        define_method(name) { get_or_set_promise(ivar) }
      end
    end
  end
end
