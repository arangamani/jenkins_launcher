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

require 'rubygems'
require 'json'
require 'fileutils'

module JenkinsLauncher
  class ConfigLoader

    def load_config(file)
      puts "Loading configuration from: #{file}"
      loaded_params = YAML.load_file(Dir.pwd + "/#{file}")
      validate_config(loaded_params)
    end

    def validate_config(loaded_params)
      valid_params = {}
      # Name
      raise "'name' is required and not set in the yml file." unless loaded_params['name']
      valid_params[:name] = loaded_params['name']

      # Node to restrict the job to
      valid_params[:node] = loaded_params['node'] if loaded_params['node']

      # Source control
      # Git, Subversion
      if loaded_params['git']
        valid_params[:scm_provider] = 'git'
        valid_params[:scm_url] = loaded_params['git']
        valid_params[:scm_branch] = loaded_params['ref'] ? loaded_params['ref'] : 'master'
      elsif loaded_params['svn']
        valid_params[:scm_provider] = 'subversion'
        valid_params[:scm_url] = loaded_params['svn']
      end

      # Shell command
      if loaded_params['script']
        valid_params[:shell_command] = ''
        loaded_params['script'].each do |command|
          valid_params[:shell_command] << command + "\n"
        end
      end
      valid_params
    end

  end
end
