#!/usr/bin/env ruby

require 'cli/ui'
require 'git'

puts 'hello world'

CLI::UI::Prompt.ask('What language/framework do you use?') do |handler|
  handler.option('rails')  { |selection| selection }
  handler.option('go')     { |selection| selection }
  handler.option('ruby')   { |selection| selection }
  handler.option('python') { |selection| selection }
end

working_dir = '.'
git = Git.open(working_dir, :log => Logger.new(STDOUT))

#g.index
#g.index.readable?
#g.index.writable?
#g.repo

git.log
  #.max_count(:all)
  #.object('README.md')
  #.since('10 years ago')
  #.between('v1.0.7', 'HEAD')
  #.map { |commit| commit.sha }

