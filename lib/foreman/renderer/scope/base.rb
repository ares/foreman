module Foreman
  module Renderer
    module Scope
      class Base
        include Foreman::Renderer::Scope::Variables
        include Foreman::Renderer::Scope::Macros::Base
        include Foreman::Renderer::Scope::Macros::TemplateLogging
        include Foreman::Renderer::Scope::Macros::SnippetRendering

        delegate :template, :to => :source, :allow_nil => true

        def initialize(source:, host: nil, params: {}, variables: {}, mode: Foreman::Renderer::REAL_MODE, template_input_values: {})
          raise "unsuported rendering mode '#{mode}'" unless AVAILABLE_RENDERING_MODES.include?(mode)

          @source = source
          @host = host
          @params = params
          @variables_keys = variables.keys
          @mode = mode
          @template_name = source.name
          variables.each { |k, v| instance_variable_set("@#{k}", v) }
          load_variables
          @template_input_values = template_input_values
        end

        attr_reader :host, :params, :variables_keys, :mode, :source, :template_input_values

        def get_binding
          binding
        end

        def allowed_variables
          @allowed_variables ||= begin
            allowed = Foreman::Renderer.config.allowed_variables + variables_keys
            instance_values.symbolize_keys.slice(*allowed)
          end
        end

        def allowed_helpers
          @allowed_helpers ||= Foreman::Renderer.config.allowed_helpers
        end
      end
    end
  end
end
