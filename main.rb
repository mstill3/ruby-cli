#!/usr/bin/env ruby

#require 'cli/ui'
#require 'git'
#
#puts 'hello world'
#
## CLI::UI::Prompt.ask('What language/framework do you use?') do |handler|
##   handler.option('rails')  { |selection| selection }
##   handler.option('go')     { |selection| selection }
##   handler.option('ruby')   { |selection| selection }
##   handler.option('python') { |selection| selection }
## end
#
#working_dir = '.'
#git = Git.open(working_dir)
#
##g.index
##g.index.readable?
##g.index.writable?
##g.repo
#
## git.log.each {|l| puts l.sha }
#  #.max_count(:all)
#  #.object('README.md')
#  #.since('10 years ago')
#  #.between('v1.0.7', 'HEAD')
#  #.map { |commit| commit.sha }
#
#puts git.branch
#
#git.branches.each { |branch|
#  puts branch
#  puts ''
#}

require 'rugged'

# Define a method for relative time display
def time_ago_in_words(time)
  distance_in_minutes = ((Time.now - time).abs / 60).round
  case distance_in_minutes
  when 0..1
    "less than a minute"
  when 2..44
    "#{distance_in_minutes} minutes"
  when 45..89
    "about an hour"
  when 90..1439
    "#{(distance_in_minutes.to_f / 60.0).round} hours"
  when 1440..2879
    "a day"
  else
    "#{(distance_in_minutes / 1440).round} days"
  end
end

# Open the repository
repo = Rugged::Repository.new('.')

# Fetch local and remote branches
branches = repo.branches.each(:local).to_a + repo.branches.each(:remote).to_a

# Sort branches by committer date
branches.sort_by! { |branch| -branch.target.time.to_i }

# Define colors
cyan = "\e[36m"
yellow = "\e[33m"
green = "\e[32m"
blue = "\e[34m"
red = "\e[31m"
reset = "\e[0m"

# Loop through each branch and print the details
branches.each do |branch|
  head = branch.head? ? '*' : ' '
  refname = branch.name
  committerdate = branch.target.time.strftime("%Y-%m-%d %H:%M:%S")
  committer_relative = time_ago_in_words(branch.target.time)
  authorname = branch.target.author[:name]
  objectname = branch.target.oid[0..6]
  subject = branch.target.message.split("\n").first

  puts "#{cyan}#{head} #{yellow}#{refname}\n      #{green}#{committer_relative} #{blue}#{authorname}\n      #{red}#{objectname} #{reset}#{subject}\n"
end

