# frozen_string_literal: true

require 'action_dispatch'

module ActionDispatch
  module Routing
    class RouteSet
      def add_localized_route(mapping, path_ast, name, anchor, scope, path, controller, default_action, to, via, formatted, options_constraints, options)
        route = RouteTranslator::Route.new(self, path, name, options_constraints, options, mapping)

        RouteTranslator::Translator.translations_for(route) do |locale, translated_name, translated_path, translated_options_constraints, translated_options|
          translated_path_ast = ::ActionDispatch::Journey::Parser.parse(translated_path)
          translated_mapping  = translate_mapping(locale, self, translated_options, translated_path_ast, scope, controller, default_action, to, formatted, via, translated_options_constraints, anchor)

          add_route_to_set translated_mapping, translated_path_ast, translated_name, anchor
        end

        if RouteTranslator.config.generate_unnamed_unlocalized_routes
          add_route_to_set mapping, path_ast, nil, anchor
        elsif RouteTranslator.config.generate_unlocalized_routes
          add_route_to_set mapping, path_ast, name, anchor
        end
      end

      def add_localed_route(locale, mapping, path_ast, name, anchor, scope, path, controller, default_action, to, via, formatted, options_constraints, options)
        #path_ast = ::ActionDispatch::Journey::Parser.parse(translated_path)

        route = RouteTranslator::Route.new(self, path, name, options_constraints, options, mapping)
        RouteTranslator::Translator::RouteHelpers.add route.name, route.route_set.named_routes

        localed_options = options.merge(locale: locale.to_s)
        scope_params = {
          blocks:      (scope[:blocks] || []).dup,
          constraints: scope[:constraints] || {},
          defaults:    scope[:defaults] || {},
          module:      scope[:module],
          options:     scope[:options] ? scope[:options].merge(localed_options) : localed_options
        }

        localed_mapping = ::ActionDispatch::Routing::Mapper::Mapping.build scope_params, self, path_ast, controller, default_action, to, via, formatted, options_constraints, anchor, options

        localed_name = "#{name}_#{locale.to_s.underscore}"
        add_route_to_set localed_mapping, path_ast, localed_name, anchor
      end

      private

      def translate_mapping(locale, route_set, translated_options, translated_path_ast, scope, controller, default_action, to, formatted, via, translated_options_constraints, anchor)
        scope_params = {
          blocks:      (scope[:blocks] || []).dup,
          constraints: scope[:constraints] || {},
          defaults:    scope[:defaults] || {},
          module:      scope[:module],
          options:     scope[:options] ? scope[:options].merge(translated_options) : translated_options
        }

        if RouteTranslator.config.verify_host_path_consistency
          scope_params[:blocks].push RouteTranslator::HostPathConsistencyLambdas.for_locale(locale)
        end

        ::ActionDispatch::Routing::Mapper::Mapping.build scope_params, route_set, translated_path_ast, controller, default_action, to, via, formatted, translated_options_constraints, anchor, translated_options
      end

      def add_route_to_set(mapping, path_ast, name, anchor)
        if method(:add_route).arity == 4
          add_route mapping, path_ast, name, anchor
        else
          add_route mapping, name
        end
      end
    end
  end
end
