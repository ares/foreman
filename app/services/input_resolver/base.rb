module InputResolver
  class Base
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
end
