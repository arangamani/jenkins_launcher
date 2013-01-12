require File.expand_path('../lib/jenkins_launcher', __FILE__)
require File.expand_path('../lib/jenkins_launcher/version', __FILE__)
require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gemspec|
  gemspec.name         = 'jenkins_launcher'
  gemspec.version      = JenkinsLauncher::VERSION
  gemspec.platform     = Gem::Platform::RUBY
  gemspec.date         = Time.now.utc.strftime("%Y-%m-%d")
  gemspec.require_path = 'lib'
  gemspec.executables  = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gemspec.files        = `git ls-files`.split("\n")
  gemspec.extra_rdoc_files = ['CHANGELOG.md', 'LICENSE', 'README.md']
  gemspec.authors      = [ 'Kannan Manickam' ]
  gemspec.email        = [ 'arangamani.kannan@gmail.com' ]
  gemspec.homepage     = 'https://github.com/arangamani/jenkins_launcher'
  gemspec.summary      = 'Jenkins Jobs Launcher through Jenkins API Client'
  gemspec.description  = %{
This is a simple easy-to-use Jenkins jobs launcher that uses jenkins_api_client.}
  gemspec.test_files = `git ls-files -- {spec}/*`.split("\n")
  gemspec.rubygems_version = '1.8.17'
end
