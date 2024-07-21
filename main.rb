#!/usr/bin/env ruby

require 'rugged'
require 'cli/ui'

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

# Initialize CLI::UI
CLI::UI::StdoutRouter.enable

# Define a hash to store branch details for selection
branch_details = {}

# Loop through each branch and store the details in the hash
branches.each do |branch|
  head = branch.head? ? '*' : ' '
  refname = branch.name
  committerdate = branch.target.time.strftime("%Y-%m-%d %H:%M:%S")
  committer_relative = time_ago_in_words(branch.target.time)
  authorname = branch.target.author[:name]
  objectname = branch.target.oid[0..6]
  subject = branch.target.message.split("\n").first

  summary_detail = "#{refname} - #{committer_relative} by #{authorname}"
  full_detail = "#{cyan}#{head} #{yellow}#{refname}\n      #{green}#{committer_relative} #{blue}#{authorname}\n      #{red}#{objectname} #{reset}#{subject}\n"

  branch_details[summary_detail] = { branch: branch, detail: full_detail }
end

# Function to display branch details
def display_branch_details(details)
  puts details
end

# Ask the user to select a branch
selected_summary_detail = CLI::UI::Prompt.ask('Select a branch:') do |handler|
  branch_details.each do |summary, details|
    handler.option(summary) { summary }
  end
end

# Retrieve the selected branch from the hash
selected_branch = branch_details[selected_summary_detail][:branch]
selected_detail = branch_details[selected_summary_detail][:detail]

# Print the selected branch details
CLI::UI::Frame.open('Branch Details') do
  display_branch_details(selected_detail)
end

# Checkout the selected branch
repo.checkout(selected_branch.name)
puts "Checked out to branch: #{selected_branch.name}"

