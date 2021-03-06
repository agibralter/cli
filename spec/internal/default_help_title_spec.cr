require "../spec_helper"

module CliInternalDefaultHelpTitleFeature
  class Optional < Cli::Command
    class Options
      string "-s"
    end
  end

  class Required < Cli::Command
    class Options
      string "-s", required: true
    end
  end

  class OptionalArg < Cli::Command
    class Options
      arg "arg"
    end
  end

  class RequiredArg < Cli::Command
    class Options
      arg "arg", required: true
    end
  end

  class Supercommand < Cli::Supercommand
  end

  class SupercommandWithDefault < Cli::Supercommand
    command "sub", default: true

    module Commands
      class Sub < Cli::Command
      end
    end
  end

  it name do
    Optional.__new_help.__default_title.should eq "optional [OPTIONS]"
    Required.__new_help.__default_title.should eq "required OPTIONS"
    OptionalArg.__new_help.__default_title.should eq "optional-arg [ARG]"
    RequiredArg.__new_help.__default_title.should eq "required-arg ARG"
    Supercommand.__new_help.__default_title.should eq "supercommand SUBCOMMAND"
    SupercommandWithDefault.__new_help.__default_title.should eq "supercommand-with-default [SUBCOMMAND]"
  end
end
