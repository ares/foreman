module Foreman
  module Renderer
    module Scope
      module Macros
        module Inputs
          extend ApipieDSL::Module
          include Foreman::Renderer::Errors

          apipie :method, desc: "Loads the information from input",
                 long_description: "Every template can be parametrized with inputs. Input needs to be explicitly defined
                   and can be of various type. During the rendering all required inputs needs to be fed with the value.
                   Most commonly, user inputs are used in report and job templates. For such input, user is requested
                   to provide values before the template rendering is performed. The input macro is substitued by the
                   corresponding value that was provided." do
            required :name, String, desc: 'parameter name'
            returns one_of: [String, true, false, Integer, Float], desc: 'value provided for the input either from user or loaded from linked parameter or fact'
            raises error: Foreman::Renderer::Errors::UndefinedInput, desc: 'when user input name does not match any stored template input. Note that template definition
              must be saved in order for this macro to be able to find it.'
          end
          def input(name)
            input = template.template_inputs&.find_by_name(name)
            if input
              preview? ? input.preview(self) : input.value(self)
            else
              raise UndefinedInput.new(s: name)
            end
          end
        end
      end
    end
  end
end
