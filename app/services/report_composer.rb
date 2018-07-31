class ReportComposer
  include ActiveModel::Model

  class InputValue
    include ActiveModel::Model

    attr_accessor :value, :template_input

    validates :value, :presence => true, :if => proc { |v| v.template_input.required? || v.value.present? }

    validates :value, :inclusion => { :in => proc { |v| v.template_input.options_array } },
              :if => proc { |v| v.template_input.input_type == 'user' && v.template_input.options_array.present? }
  end

  class UiParams
    attr_reader :ui_params
    def initialize(ui_params)
      @ui_params = ui_params.permit!
    end

    def params
      { :template_id => ui_params[:id],
        :input_values => report_base_params[:input_values]}.with_indifferent_access
    end

    def blank_to_nil(thing)
      thing.blank? ? nil : thing
    end

    def report_base_params
      ui_params[:report_template_report] || {}.with_indifferent_access
    end
  end

  def initialize(params)
    @params = params
    @template = load_report_template(params[:template_id])
    @input_values = build_inputs(@template, params[:input_values])
  end

  def self.from_ui_params(ui_params)
    self.new(UiParams.new(ui_params).params)
  end

  def build_inputs(template, input_values)
    inputs = {}.with_indifferent_access
    return inputs if template.nil?

    # process values from params
    if input_values.present?
      @template.template_inputs.each do |input|
        inputs[input.id.to_s] = InputValue.new(value: input_values[input.id.to_s].try(:[], 'value'), template_input: input)
      end
    end

    inputs
  end

  def valid?
    super & @input_values.map { |_, input_value| input_value.valid? }.all?
  end

  def template_input_values
    Hash[@input_values.map { |_, input_value| [input_value.template_input.name, input_value.value] }]
  end

  def input_value_for(input)
    @input_values[input.id.to_s]
  end

  def load_report_template(id)
    ReportTemplate.authorized(:generate_report_template).find_by_id(id)
  end

end
