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
require 'thor'

module JenkinsLauncher
  class CLI < Thor

    class_option :username,        :aliases => "-u", :desc => "Name of Jenkins user"
    class_option :password,        :aliases => "-p", :desc => "Password of Jenkins user"
    class_option :password_base64, :aliases => "-b", :desc => "Base 64 encoded password of Jenkins user"
    class_option :server_ip,       :aliases => "-s", :desc => "Jenkins server IP address"
    class_option :server_port,     :aliases => "-o", :desc => "Jenkins server port"
    class_option :creds_file,      :aliases => "-c", :desc => "Credentials file for communicating with Jenkins server"
    class_option :quiet_period,    :aliases => "-q", :desc => "Jenkins Quit period to wait before getting console output."

    map "-v" => :version

    def initialize(arg1, arg2, arg3)
      super
      @api = APIInterface.new(options)
      @config = ConfigLoader.new
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
      else
        puts "The job is already created. Please use 'start' command to build the job."
      end
    end

    desc "start CONFIG", "Load configuration, create job on jenkins, and build"
    def start(config_file)
      params = @config.load_config(config_file)
      @api.create_job(params) unless @api.job_exists?(params[:name])
      unless @api.job_building?(params[:name])
        @api.build_job(params[:name])
        quiet_period = options[:quiet_period] ? options[:quiet_period] : 5
        sleep quiet_period
        @api.display_progressive_console_output(params[:name])
        puts "Build status: #{@api.get_job_status(params[:name])}"
        @api.delete_job(params[:name])
      else
        puts "Build is already running. Run attach command to 'attach' to existing build and watch progress."
      end
    end

    desc "stop CONFIG", "Stop already running build of the job"
    def stop(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "The job doesn't exist"
      elsif !@api.job_building?(params[:name])
        puts "The job is currently not building. It may have finished."
      else
        @api.stop_job(params[:name])
      end
    end

    desc "attach CONFIG", "Attach to already running build if any"
    def attach(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "Job is not created. Please use the 'start' command to create and build the job."
      elsif !@api.job_building?(params[:name])
        puts "Job is not running. Please use the 'start' command to build the job."
      else
        @api.display_progressive_console_output(params[:name])
        puts "Build status: #{@api.get_job_status(params[:name])}"
        @api.delete_job(params[:name])
      end
    end

    desc "destroy CONFIG", "Destroy the job from Jenkins server"
    def destroy(config_file)
      params = @config.load_config(config_file)
      if !@api.job_exists?(params[:name])
        puts "The job doesn't exist or already destroyed."
      elsif @api.job_building?(params[:name])
        msg = ''
        msg << "The job is currently building. Please use the 'stop' command or wait until the build is completed."
        msg << " If you would like to watch the progress, use the 'attach' command."
        puts msg
      else
        @api.delete_job(params[:name])
      end
    end

  end
end
