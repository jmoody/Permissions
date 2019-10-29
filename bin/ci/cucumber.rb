#!/usr/bin/env ruby

require "run_loop"
require "luffa"

cucumber_args = "#{ARGV.join(" ")}"

this_dir = File.expand_path(File.dirname(__FILE__))
working_directory = File.join(this_dir, "..", "..")

def languages
  languages = ["da_DK","ru_RU","en_US","ja_JP"]
  threads = []
  languages.each do |item|
    threads << Thread.new(item) do |i|
      exit_code = Luffa.unix_command("language=#{i} ./bin/ci/appcenter.sh ")
      puts "exit code language #{i} is #{exit_code}"
    end
  end
  threads.each { |thr| thr.join }
end
# on-simulator tests of features in test/cucumber
languages
Dir.chdir(working_directory) do

  FileUtils.rm_rf("reports")
  FileUtils.mkdir_p("reports")

  xcode = RunLoop::Xcode.new
  RunLoop::CoreSimulator.terminate_core_simulator_processes

  simctl = RunLoop::Simctl.new
  instruments = RunLoop::Instruments.new
  options = {}
  match = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
  env_vars = {"DEVICE_TARGET" => match.udid}

  languagesLiterals = ["en", "ru"]

  languagesLiterals.each do |item|
    language = "APP_LANG=#{item} APP_LOCALE=#{item}"
    args = [
      "bundle", "exec",
      "cucumber", "-p", "default",
      "-f", "json", "-o", "reports/#{item}.json",
      "-f", "junit", "-o", "reports/junit/#{item}",
      "#{language}"
    ]

    exit_code = Luffa.unix_command(args.join(" "), {:exit_on_nonzero_status => true,
                                                :env_vars => env_vars})
  end
end
