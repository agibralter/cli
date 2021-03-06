require "../spec_helper"

module CliInternalHelpHandlerDslFeature
  class Default < Cli::Command
    class Options
      help
    end
  end

  class Specific < Cli::Command
    class Options
      help "--show-help", desc: "help!"
    end
  end

  macro test(example, klass, names, desc)
    it {{example}} do
      handler = {{klass.id}}::Options.definitions.handlers[{{names[0]}}]
      handler.names.should eq {{names}}
      {% for e, i in names %}
        Stdio.capture do |io|
          {{klass.id}}.run [{{e}}]
          io.out.gets_to_end.should eq <<-EOS
            {{klass.downcase.id}}

            Options:
              #{ ({{names}}).join(", ") }  {{desc.id}}\n
            EOS
        end
      {% end %}
    end
  end

  describe name do
    test "default", "Default", %w(-h --help), "show this help"
    test "specific", "Specific", %w(--show-help), "help!"
  end
end
