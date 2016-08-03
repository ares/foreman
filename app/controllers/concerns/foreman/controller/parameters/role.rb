module Foreman::Controller::Parameters::Role
  extend ActiveSupport::Concern

  class_methods do
    def role_params_filter
      Foreman::ParameterFilter.new(::Role).tap do |filter|
        filter.permit :name
      end
    end
  end

  def role_params
    self.class.role_params_filter.filter_params(params, parameter_filter_context)
  end

  def taxonomy_params!
    params[:role].delete(:organization_ids).to_a + params[:role].delete(:location_ids).to_a
  end
end
