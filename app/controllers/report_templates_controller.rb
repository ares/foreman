class ReportTemplatesController < TemplatesController
  include Foreman::Controller::Parameters::ReportTemplate
  helper_method :documentation_anchor

  def documentation_anchor
    '4.11ReportTemplates'
  end

  def generate
    find_resource
    @composer = ReportComposer.from_ui_params(params)
  end

  def schedule_report
    find_resource
    @composer = ReportComposer.from_ui_params(params)
    if @composer.valid?
      safe_render(@template, template_input_values: @composer.template_input_values)
      if response.status < 400
        headers["Cache-Control"] = "no-cache"
        headers["Content-Disposition"] = %(attachment; filename="#{@template.suggested_report_name}")
        return
      end
    end

    error _('Could not generate the report, check the form for error messages'), :now => true
    render :generate
  end

  private

  def action_permission
    case params[:action]
      when 'generate', 'schedule_report'
        'generate'
      else
        super
    end
  end
end
