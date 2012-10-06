require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'
require 'appraisal'

desc 'Default: run rails_legacy_mapper tests.'
task :default => :test

desc 'Test the sortifiable gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the rails_legacy_mapper gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Rails Legacy Mapper'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
