class TemplateInput < ApplicationRecord
  include ::Exportable

  class ValueNotReady < ::Foreman::Exception
  end
  class UnsatisfiedRequiredInput < ::Foreman::Exception
  end

  TYPES = { :user => N_('User input'), :fact => N_('Fact value'), :variable => N_('Variable'),
            :puppet_parameter => N_('Puppet parameter') }.with_indifferent_access

  attr_exportable(:name, :required, :input_type, :fact_name, :variable_name, :puppet_class_name,
                  :puppet_parameter_name, :description, :options, :advanced)

  belongs_to :template
  # TODO also need to be converted including template_invocations
  # has_many :template_invocation_input_values, :dependent => :destroy

  scoped_search :on => :name, :complete_value => true
  scoped_search :on => :input_type, :complete_value => true

  validates :name, :presence => true, :uniqueness => { :scope => 'template_id' }
  validates :input_type, :presence => true, :inclusion => TemplateInput::TYPES.keys

  validates :fact_name, :presence => { :if => :fact_template_input? }
  validates :variable_name, :presence => { :if => :variable_template_input? }
  validates :puppet_parameter_name, :puppet_class_name, :presence => { :if => :puppet_parameter_template_input? }

  def user_template_input?
    input_type == 'user'
  end

  def fact_template_input?
    input_type == 'fact'
  end

  def variable_template_input?
    input_type == 'variable'
  end

  def puppet_parameter_template_input?
    input_type == 'puppet_parameter'
  end

  def preview(scope)
    get_resolver(scope).preview
  end

  def value(scope)
    get_resolver(scope).value
  end

  def options_array
    self.options.blank? ? [] : self.options.split(/\r?\n/).map(&:strip)
  end

  def basic?
    !advanced
  end

  private

  def get_resolver(scope)
    resolver_class = case input_type
                     when 'user'
                       UserInputResolver
                     when 'fact'
                       FactInputResolver
                     when 'variable'
                       VariableInputResolver
                     when 'puppet_parameter'
                       PuppetParameterInputResolver
                     else
                       raise "unknown template input type #{input_type.inspect}"
                     end
    resolver_class.new(self, scope)
  end

  class InputResolver
    def initialize(input, scope)
      @input = input
      @scope = scope
    end

    def preview
      ready? ? resolved_value : preview_value
    end

    def value
      ready? ? resolved_value : raise(ValueNotReady, "Input '#{@input.name}' is not ready for rendering")
    end

    def preview_value
      "$#{@input.input_type.upcase}_INPUT[#{@input.name}]"
    end

    # should be defined in descendants
    def ready?
      raise NotImplementedError
    end

    # should be defined in descendants
    def resolved_value
      raise NotImplementedError
    end
  end

  class UserInputResolver < InputResolver

    def value
      raise(UnsatisfiedRequiredInput, _("Value for required input '%s' was not specified") % @input.name) if required_value_needed?
      super
    end

    def ready?
      @scope.template_input_values.key?(@input.name)
    end

    def resolved_value
      input_value
    end

    private

    def required_value_needed?
      @input.required? && input_value.blank?
    end

    def input_value
      return unless @scope.template_input_values.key?(@input.name)
      @scope.template_input_values[@input.name]
    end
  end

  class FactInputResolver < InputResolver
    # fact might not be present if it hasn't been uploaded yet, there's typo in name
    def ready?
      @scope.host && get_fact.present?
    end

    def resolved_value
      get_fact.value
    end

    private

    def get_fact
      @fact ||= @scope.host.fact_values.includes(:fact_name).find_by(:'fact_names.name' => @input.fact_name)
    end
  end

  class VariableInputResolver < InputResolver
    def ready?
      @scope.host && @scope.host.params.key?(@input.variable_name)
    end

    def resolved_value
      @scope.host.params[@input.variable_name]
    end
  end

  class PuppetParameterInputResolver < InputResolver
    def ready?
      @scope.host &&
        get_enc.key?(@input.puppet_class_name) &&
        get_enc[@input.puppet_class_name].is_a?(Hash) &&
        get_enc[@input.puppet_class_name].key?(@input.puppet_parameter_name)
    end

    def resolved_value
      get_enc[@input.puppet_class_name][@input.puppet_parameter_name]
    end

    private

    def get_enc
      @enc ||= if SETTINGS[:version].short <= '1.15'
                 Classification::ClassParam.new(:host => @scope.host).enc
               else
                 HostInfoProviders::PuppetInfo.new(@scope.host).puppetclass_parameters
               end
    end
  end
end
