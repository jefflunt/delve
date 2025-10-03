module Soak
  module Plugins
    class Base
      def self.plugins
        @plugins ||= {}
      end

      def self.inherited(descendant)
        super
        plugin_name = descendant.name.split('::').last.downcase
        Soak::Plugins::Base.plugins[plugin_name] = descendant
      end
    end
  end
end

