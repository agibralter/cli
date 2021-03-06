module Cli
  abstract class CommandBase
    macro __define_supercommand(type)
      {% type = type.resolve %}
      def self.__supercommand
        {% if type < ::Cli::Supercommand %}
          ::{{type}}
        {% end %}
      end
    end

    macro inherited
      {%
        name_components = @type.name.split("::")
        if name_components.size > 3 && name_components[-2] == "Commands"
          outer_module = name_components[0..-3].join("::").id
        else
          outer_module = nil
        end
      %}

      {% if outer_module %}
        __define_supercommand ::{{outer_module}}
      {% else %}
        def self.__supercommand
        end
      {% end %}

      {% if @type.superclass != ::Cli::CommandBase %}
        {%
          if @type.superclass == ::Cli::Command
            super_option_data = "Cli::OptionModel".id
            super_help = "Cli::Helps::Command".id
          elsif @type.superclass == ::Cli::Supercommand
            super_option_data = "Cli::OptionModel".id
            super_help = "Cli::Helps::Supercommand".id
          else
            super_option_data = "#{@type.superclass}::Options".id
            super_help = "#{@type.superclass}::Help".id
          end %}

        class Options < ::{{super_option_data}}
          {% if @type.superclass == ::Cli::Supercommand %}
            arg "subcommand", stop: true
          {% end %}

          def command; __command; end
          def __command
            @__command.as(::{{@type}})
          end
        end

        class Help < ::{{super_help}}
          def __command_class; self.class.__command_class; end
          def self.__command_class
            ::{{@type}}
          end

          def __option_class; self.class.__option_class; end
          def self.__option_class
            ::{{@type}}::Options
          end
        end

        def option_data; __option_data; end
        def __option_data
          @__option_data.as(Options)
        end

        def self.__new_help(indent = 2)
          Help.new(indent: indent)
        end

        def self.__help_model
          Help
        end

        {%
          names = @type.id.split("::")
          enclosing_class_name = names.size >= 3 ? names[0..-3].join("::").id : nil
        %}

        def self.__enclosing_class
          {% if enclosing_class_name %}
            ::{{enclosing_class_name}}
          {% end %}
        end

        def __new_options(argv)
          Options.new(self, argv)
        end
      {% end %}
    end

    def self.run(argv = %w())
      __run(argv)
    end

    @@__running = false

    def self.__run(argv)
      if @@__running
        __run_without_rescue(argv)
      else
        @@__running = true
        begin
          result = __run_with_rescue(argv)
        ensure
          @@__running = false
        end
      end
    end

    def self.__run_without_rescue(argv)
      new(nil, argv).__run
    end

    def self.__run_with_rescue(argv)
      new(nil, argv).__run
      0
    rescue ex : ::Cli::Exit
      out = ex.status == 0 ? ::STDOUT : ::STDERR
      out.puts ex.message if ex.message
      ex.status
    end

    getter __parent : ::Cli::CommandBase?

    def initialize(@__parent, argv)
      self.class.__finalize_definition
      __initialize_options argv
    end

    @__option_data : ::Optarg::Model?
    def __option_data
      @__option_data.as(::Optarg::Model)
    end

    def options; __options; end
    def __options; __option_data.__options; end

    def args; __args; end
    def __args; __option_data.__args; end

    def named_args; __named_args; end
    def __named_args; __option_data.__named_args; end

    def nameless_args; __nameless_args; end
    def __nameless_args; __option_data.__nameless_args; end

    def parsed_args; __parsed_args; end
    def __parsed_args; __option_data.__parsed_args; end

    def unparsed_args; __unparsed_args; end
    def __unparsed_args; __option_data.__unparsed_args; end

    def version; __version; end
    def __version; self.class.__version; end

    def version?; __version?; end
    def __version?; self.class.__version?; end

    def self.__local_name
      ::StringInflection.kebab(name.split("::").last)
    end

    def self.__help_on_parsing_error?
      true
    end

    def self.__version
      if v = __version?
        v.as(::String)
      elsif sc = __supercommand
        sc.__version
      else
        raise "No version."
      end
    end

    def self.__version?
      nil
    end

    macro command_name(value)
      def self.__local_name
        {{value}}
      end
    end

    macro disable_help_on_parsing_error!
      def self.__help_on_parsing_error?
        false
      end
    end

    macro version(value)
      def self.__version?
        {{value}}
      end
    end

    @@__global_name : String?
    def self.__global_name
      @@__global_name ||= begin
        if enclosing_class = __enclosing_class
          if enclosing_class.responds_to?(:__global_name)
            return "#{enclosing_class.__global_name} #{__local_name}"
          end
        end
        __local_name
      end
    end

    def help!(message = nil, error = nil, code = nil, indent = 2)
      __help! message, error, code, indent
    end

    def __help!(message = nil, error = nil, code = nil, indent = 2)
      error = !message.nil? if error.nil?
      __exit! message, error, code, true, indent
    end

    def exit!(message = nil, error = false, code = nil, help = false, indent = 2)
      __exit! message, error, code, help, indent
    end

    def __exit!(message = nil, error = false, code = nil, help = false, indent = 2)
      a = %w()
      a << message if message
      if help
        if help = self.class.__new_help(indent: indent).__text
          a << help
        end
      end
      message = a.join("\n\n") unless a.empty?
      code ||= error ? 1 : 0
      raise ::Cli::Exit.new(message, code)
    end

    def error!(message = nil, code = nil, help = false, indent = 2)
      __error! message, code, help, indent
    end

    def __error!(message = nil, code = nil, help = false, indent = 2)
      __exit! message, true, code, help, indent
    end

    def version!
      __version!
    end

    def __version!
      __exit! version
    end

    def run
      raise "Not implemented."
    end

    def __run
      run
    end

    def __rescue_parsing_error
      yield
    rescue ex : ::Optarg::ParsingError
      exit! "Parsing Error: #{ex.message}", error: true, help: self.class.__help_on_parsing_error?
    end
  end
end
