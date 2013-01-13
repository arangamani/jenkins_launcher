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

require 'jenkins_api_client'

module JenkinsLauncher
  class APIInterface

    def initialize(options)
      if options[:username] && options[:server_ip] && (options[:password] || options[:password_base64])
        creds = options
      elsif options[:creds_file]
        creds = YAML.load_file(File.expand_path(options[:creds_file], __FILE__))
      elsif File.exist?("#{ENV['HOME']}/.jenkins_api_client/login.yml")
        creds = YAML.load_file(File.expand_path("#{ENV['HOME']}/.jenkins_api_client/login.yml", __FILE__))
      else
        puts "Credentials are not set. Please pass them as parameters or set them in the default credentials file"
        exit 1
      end
      @client = JenkinsApi::Client.new(creds)
    end

    def create_job(params)
      @client.job.create_freestyle(params) unless @client.job.exists?(params[:name])
    end

    def build_job(name)
      @client.job.build(name) unless @client.job.get_current_build_status(name) == 'running'
    end

    def stop_job(name)
      @client.job.stop_build(name)
    end

    def job_exists?(name)
      @client.job.exists?(name)
    end

    def job_building?(name)
      @client.job.get_current_build_status(name) == 'running'
    end

    def delete_job(name)
      @client.job.delete(name)
    end

    def get_job_status(name)
      @client.job.get_current_build_status(name)
    end

    def display_progressive_console_output(name, refresh_rate)
      debug_changed = false
      if @client.debug == true
        @client.debug = false
        debug_changed = true
      end

      response = @client.job.get_console_output(name)
      puts response['output'] unless response['more']
      while response['more']
        size = response['size']
        puts response['output'] unless response['output'].chomp.empty?
        sleep refresh_rate
        response = @client.job.get_console_output(name, 0, size)
      end
      # Print the last few lines
      puts response['output'] unless response['output'].chomp.empty?
      @client.toggle_debug if debug_changed
    end

  end
end
