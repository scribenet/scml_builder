require 'rake/testtask'
require 'rspec/core/rake_task'

namespace :minitest do
  Rake::TestTask.new(:all) do |t|
    t.libs << "test"
    t.test_files = FileList['test/test*.rb']
  end
end

RSpec::Core::RakeTask.new(:spec)

task :minitest => ['minitest:all']
task :test => [ :minitest ]
task :default => :test
