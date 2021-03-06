require "../../spec_helper"

module CliOptargFeatureDetail
  class Command < Cli::Command
    class Options
      arg "arg"
      string "-s"
      terminator "--"
    end

    def run
      puts args.arg
      puts options.s
      puts unparsed_args[0]
    end
  end

  it name do
    Stdio.capture do |io|
      Command.run %w(foo -s bar -- baz)
      io.out.gets_to_end.should eq <<-EOS
        foo
        bar
        baz\n
        EOS
    end
  end
end
