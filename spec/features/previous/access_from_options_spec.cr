require "../../spec_helper"

module CliAccessFromOptionsPreviousFeature
  class Command < Cli::Command
    class Options
      on("--go") { command.go(with: "the Wind") }
    end

    def go(with some)
      puts "Gone with #{some}"
      raise ::Cli::Exit.new
    end
  end

  it name do
    Stdio.capture do |io|
      Command.run(%w(--go))
      io.out.gets_to_end.should eq "Gone with the Wind\n"
    end
  end
end
