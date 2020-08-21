# frozen_string_literal: true

require 'action_dispatch'

module ActionDispatch
  module Routing
    class Mapper
      def localized
        @localized = true
        yield
        @localized = false
      end

      def locale(_locale)
        @locale = _locale
        yield
        @locale = nil
      end

      # rubocop:disable Lint/UnderscorePrefixedVariableName, Metrics/PerceivedComplexity
      def add_route(action, controller, options, _path, to, via, formatted, anchor, options_constraints) # :nodoc:
        return super unless @localized || @locale.present?

        path = path_for_action(action, _path)
        raise ArgumentError, 'path is required' if path.blank?

        action = action.to_s

        default_action = options.delete(:action) || @scope[:action]

        if %r{^[\w\-\/]+$}.match?(action)
          default_action ||= action.tr('-', '_') unless action.include?('/')
        else
          action = nil
        end

        as = if !options.fetch(:as, true) # if it's set to nil or false
               options.delete(:as)
             else
               name_for_action(options.delete(:as), action)
             end

        path = Mapping.normalize_path URI.parser.escape(path), formatted
        ast = Journey::Parser.parse path

        if @localed
          options_constraints = options_constraints.merge(locale: @locale)
        end

        mapping = Mapping.build(@scope, @set, ast, controller, default_action, to, via, formatted, options_constraints, anchor, options)

        if @localized
          @set.add_localized_route(mapping, ast, as, anchor, @scope, path, controller, default_action, to, via, formatted, options_constraints, options)
        elsif @locale.present?
          @set.add_localed_route(@locale, mapping, ast, as, anchor, @scope, path, controller, default_action, to, via, formatted, options_constraints, options)
        end
      end
      # rubocop:enable Lint/UnderscorePrefixedVariableName, Metrics/PerceivedComplexity

      private

      def define_generate_prefix(app, name)
        return super unless @localized || @locale.present?

        if @localized
          RouteTranslator::Translator.available_locales.each do |locale|
            super(app, "#{name}_#{locale.to_s.underscore}")
          end
        elsif @locale.present?
          super(app, "#{name}_#{@locale.to_s.underscore}")
        end
      end
    end
  end
end
