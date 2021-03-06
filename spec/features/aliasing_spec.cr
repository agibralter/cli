require "../spec_helper"

module CliAliasingFeature
  class Command < ::Cli::Supercommand
    command "loooooooooong"
    command "l", aliased: "loooooooooong"

    module Commands
      class Loooooooooong < ::Cli::Command
        def run
          puts "sleep!"
        end
      end
    end
  end

  it name do
    Stdio.capture do |io|
      Command.run %w(l)
      io.out.gets_to_end.should eq "sleep!\n"
    end
  end
end
