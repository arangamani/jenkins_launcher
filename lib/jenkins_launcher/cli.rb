#
# Copyright (c) 2013 Kannan Manickam <arangamani.kannan@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require File.expand_path('../config_loader', __FILE__)
require File.expand_path('../api_interface', __FILE__)
require File.expand_path('../core_ext', __FILE__)
require 'thor'

module JenkinsLauncher
  class CLI < Thor

    class_option :username,        :aliases => "-u", :desc => "Name of Jenkins user"
    class_option :password,        :aliases => "-p", :desc => "Password of Jenkins user"
    class_option :password_base64, :aliases => "-b", :desc => "Base 64 encoded password of Jenkins user"
    class_option :server_ip,       :aliases => "-s", :desc => "Jenkins server IP address"
    class_option :server_port,     :aliases => "-o", :desc => "Jenkins server port"
    class_option :creds_file,      :aliases => "-c", :desc => "Credentials file for communicating with Jenkins server"

    map "-v" => :version

    def initialize(arg1, arg2, arg3)
      super
      @api = APIInterface.new(options)
      @config = ConfigLoader.new
    end

    no_tasks do
      def print_status(status)
        case status
        when "success"
          puts "Build status: #{status.upcase}".green
        when "failure"
          puts "Build status: #{status.upcase}".red
        when "unstable"
          puts "Build status: #{status.upcase}".yellow
        else
          puts "Build status: #{status.upcase}"
        end
      end
    end

    desc "version", "Shows current version"
    def version
      puts JenkinsLauncher::VERSION
    end

    desc "create CONFIG", "Load configuration and create a job on jenkins"
    def create(config_file)
      params = @config.load_config(config_file)
      unless @api.job_exists?(params[:name])
        @api.create_job(params)
        @api.use_node(params[:name], params[:node]) if params[:node]
        puts "The Job '#{params[:name]}' is created successfully.".green
      else
        puts "The job is already created. Please use 'start' command to build the job.".yellow
      end
    end

    desc "start CONFIG", "Load configuration, create job on jenkins, and build"
    method_option :quiet_period, :aliases => "-q", :desc => "Jenkins Quit period to wait before starting to get console output. Default is '5' seconds"
    method_option :refresh_rate, :aliases => "-r", :desc => "Time to wait between getting console output from server. Default is '5' seconds"
    method_option :delete_after, :type => :boolean, :aliases => "-d", :desc => "Delete the job from Jenkins after the build is finished"
    def start(config_file)
      params = @config.load_config(config_file)
      unless @api.job_exists?(params[:name])
        @api.create_job(params)
        @api.use_node(params[:name], params[:node]) if params[:node]
      end
      unless @api.job_building?(params[:name])
        @api.build_job(params[:name])
        quiet_period = options[:quiet_period] ? options[:quiet_period] : 5
        sleep quiet_period
        refresh_rate = options[:refresh_rate] ? options[:refresh_rate].to_i : 5
        @api.display_progressive_console_output(params[:name], refresh_rate)
        print_status(@api.get_job_status(params[:name]))
        @api.delete_job(params[:name]) if options[:delete_after]
      else
        puts "Build is already running. Run 'attach' command to attach to existing build and watch progress.".yellow
      end
    end

    desc "stop CONFIG", "Stop already running build of the job"
    def stop(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "The job doesn't exist".red
      elsif !@api.job_building?(params[:name])
        puts "The job is currently not building or it may have finished already.".yellow
      else
        @api.stop_job(params[:name])
      end
    end

    desc "attach CONFIG", "Attach to already running build if any"
    method_option :refresh_rate, :aliases => "-r", :desc => "Time to wait between getting console output from server. Default is '5' seconds"
    method_option :delete_after, :type => :boolean, :aliases => "-d", :desc => "Delete the job from Jenkins after the build is finished"
    def attach(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "Job is not created. Please use the 'start' command to create and build the job.".red
      elsif !@api.job_building?(params[:name])
        puts "Job is not running. Please use the 'start' command to build the job.".yellow
      else
        refresh_rate = options[:refresh_rate] ? options[:refresh_rate].to_i : 5
        @api.display_progressive_console_output(params[:name], refresh_rate)
        print_status(@api.get_job_status(params[:name]))
        @api.delete_job(params[:name]) if options[:delete_after]
      end
    end

    desc "console CONFIG", "Show the console output of the recent build if any"
    def console(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "Job is not created. Please use the 'create' or 'start' command to create or/and build the job.".red
      elsif @api.job_building?(params[:name])
        puts "The job is currently building. Please use the 'attach' command to attach to the running build and watch progress".yellow
      else
        @api.display_progressive_console_output(params[:name], 5)
      end
    end

    desc "destroy CONFIG", "Destroy the job from Jenkins server"
    method_option :force, :type => :boolean, :aliases => "-f", :desc => "Stop the job if it is already running"
    def destroy(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "The job doesn't exist or already destroyed.".yellow
      elsif @api.job_building?(params[:name]) && !options[:force]
        msg = ''
        msg << "The job is currently building. Please use the 'stop' command or wait until the build is completed."
        msg << " The --force option can be used to stop the build and destroy immediately."
        msg << "  If you would like to watch the progress, use the 'attach' command."
        puts msg.yellow
      else
        @api.stop_job(params[:name]) if options[:force] && @api.job_building?(params[:name])
        @api.delete_job(params[:name])
        puts "The job '#{params[:name]}' is destroyed successfully.".green
      end
    end

  end
end
