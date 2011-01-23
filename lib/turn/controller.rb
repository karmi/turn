require 'fileutils'

module Turn
  require 'turn/components/suite.rb'
  require 'turn/components/case.rb'
  require 'turn/components/method.rb'

  # = Controller
  #
  #--
  # TODO: Add support to test run loggging.
  #++
  class Controller

    # List of if file names or glob pattern of tests to run.
    attr_accessor :tests

    # List of file names or globs to exclude from +tests+ list.
    attr_accessor :exclude

    # Regexp pattern that all test name's must
    # match to be eligible to run.
    attr_accessor :pattern

    # Add these folders to the $LOAD_PATH.
    attr_accessor :loadpath

    # Libs to require when running tests.
    attr_accessor :requires

    # Reporter type.
    attr_accessor :format

    # Run mode.
    attr_accessor :runmode

    # Test against live install (i.e. Don't use loadpath option)
    attr_accessor :live

    # Log results? May be true/false or log file name. (TODO)
    attr_accessor :log

    # Verbose output?
    attr_accessor :verbose

    # Test framework, either :minitest or :testunit
    attr_accessor :framework

    def verbose? ; @verbose ; end
    def live?    ; @live    ; end

  private

    def initialize
      yield(self) if block_given?
      initialize_defaults
    end

    #
    def initialize_defaults
      @loadpath ||= ['lib']
      @tests    ||= ["test/**/{test,}*{,test}.rb"]
      @exclude  ||= []
      @requires ||= []
      @live     ||= false
      @log      ||= true
      #@format  ||= nil
      #@runner   ||= RUBY_VERSION >= "1.9" ? MiniRunner : TestRunner
      @pattern  ||= /.*/
    end

    # Collect test configuation.
    #def test_configuration(options={})
    #  #options = configure_options(options, 'test')
    #  #options['loadpath'] ||= metadata.loadpath
    #  options['tests']    ||= self.tests
    #  options['loadpath'] ||= self.loadpath
    #  options['requires'] ||= self.requires
    #  options['live']     ||= self.live
    #  options['exclude']  ||= self.exclude
    #  #options['tests']    = list_option(options['tests'])
    #  options['loadpath'] = list_option(options['loadpath'])
    #  options['exclude']  = list_option(options['exclude'])
    #  options['require']  = list_option(options['require'])
    #  return options
    #end

    #
    def list_option(list)
      case list
      when nil
        []
      when Array
        list
      else
        list.split(/[:;]/)
      end
    end

  public

    def tests=(paths)
      @tests = list_option(paths)
    end

    def loadpath=(paths)
      @loadpath = list_option(paths)
    end

    def exclude=(paths)
      @exclude = list_option(paths)
    end

    def requires=(paths)
      @requires = list_option(paths)
    end

    # Test files.
    def files
      @files ||= (
        fs = tests.map do |t|
          File.directory?(t) ? Dir[File.join(t, '**', '*')] : Dir[t]
        end
        fs = fs.flatten.reject{ |f| File.directory?(f) }

        ex = exclude.map do |x|
          File.directory?(x) ? Dir[File.join(x, '**', '*')] : Dir[x]
        end
        ex = ex.flatten.reject{ |f| File.directory?(f) }

        (fs - ex).uniq.map{ |f| File.expand_path(f) }
      )
    end

    def start
      @files = nil  # reset files just in case

      if files.empty?
        $stderr.puts "No tests."
        return
      end

      testrun = runner.new(self)

      testrun.start
    end

    # Select reporter based on output mode.
    def reporter
      @reporter ||= (
        case format
        when :marshal
          require 'turn/reporters/marshal_reporter'
          Turn::MarshalReporter.new($stdout)
        when :progress
          require 'turn/reporters/progress_reporter'
          Turn::ProgressReporter.new($stdout)
        when :dotted
          require 'turn/reporters/dot_reporter'
          Turn::DotReporter.new($stdout)
        when :pretty
          require 'turn/reporters/pretty_reporter'
          Turn::PrettyReporter.new($stdout)
        when :cue
          require 'turn/reporters/cue_reporter'
          Turn::CueReporter.new($stdout)
        else
          require 'turn/reporters/outline_reporter'
          Turn::OutlineReporter.new($stdout)
        end
      )
    end

    # # Insatance of Runner, selected based on format and runmode.
    def runner
      @runner ||= (
        case framework
        when :minitest
          require 'turn/runners/minirunner'
        else
          require 'turn/runners/testrunner'
        end

        case runmode
        when :marshal
          if framework == :minitest
            Turn::MiniRunner
          else
            Turn::TestRunner
          end
        when :solo
          require 'turn/runners/solorunner'
          Turn::SoloRunner
        when :cross
          require 'turn/runners/crossrunner'
          Turn::CrossRunner
        else
          if framework == :minitest
            Turn::MiniRunner
          else
            Turn::TestRunner
          end
        end
      )
    end

  end

end

