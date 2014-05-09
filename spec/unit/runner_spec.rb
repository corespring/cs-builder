require 'cs-builder/runner'


include CsBuilder

describe Runner do


  class TestRunner
    include Runner

    def runner_log(msg)
      puts "! #{msg}"
    end

    def runner_error(path)
     "Error -> #{path}" 
    end


    def run(lock, sleep_length)
      puts "run -> #{lock}"
      run_with_lock(lock){

        puts "now running - sleep for: #{sleep_length}"
        sleep sleep_length
      }
    end
  end

  it "should throw an error on the 2nd call for the same lock path" do

    error = TestRunner.new.runner_error("spec/tmp/one.lock")

    expect {
      threads = []
      threads << Thread.new {
        two = TestRunner.new
        two.run("spec/tmp/one.lock", 3)
      }

      threads << Thread.new {
        sleep 1
        two = TestRunner.new
        two.run("spec/tmp/one.lock", 1)
      }
      threads.each { |t| t.join  }
    }.to raise_error(error)
  end

end
