#!/usr/bin/env ruby

require 'rugged'
require 'tty-prompt'
require 'pastel'

# Define a method for relative time display
def time_ago_in_words(time)
  distance_in_minutes = ((Time.now - time).abs / 60).round
  case distance_in_minutes
  when 0..1
    "less than a minute ago"
  when 2..44
    "#{distance_in_minutes} minutes ago"
  when 45..89
    "about an hour ago"
  when 90..1439
    "#{(distance_in_minutes.to_f / 60.0).round} hours ago"
  when 1440..2879
    "a day ago"
  else
    "#{(distance_in_minutes / 1440).round} days ago"
  end
end

# Open the repository from the current directory
begin
  repo_path = Dir.pwd
  puts repo_path
  repo = Rugged::Repository.new(repo_path)
rescue Rugged::RepositoryError => e
  puts "Error: #{e.message}"
  exit 1
end

# Fetch local and remote branches
branches = repo.branches.each(:local).to_a + repo.branches.each(:remote).to_a

# Sort branches by committer date
branches.sort_by! { |branch| -branch.target.time.to_i }

# Initialize TTY Prompt and Pastel for coloring
prompt = TTY::Prompt.new
pastel = Pastel.new

# Define a hash to store branch details for selection
branch_details = {}

# Calculate the maximum lengths for formatting
max_refname_length = branches.map { |branch| branch.name.length }.max
max_committer_relative_length = branches.map { |branch| time_ago_in_words(branch.target.time).length }.max
max_authorname_length = branches.map { |branch| branch.target.author[:name].length }.max

# Loop through each branch and store the details in the hash
branches.each do |branch|
  head = branch.head? ? '*' : ' '
  refname = branch.name
  commit = branch.target
  committer_relative = time_ago_in_words(commit.time)
  authorname = commit.author[:name]
  objectname = commit.oid[0..6]
  subject = commit.message.split("\n").first

  # Color each part individually
  colored_refname = pastel.yellow(refname.ljust(max_refname_length))
  colored_committer_relative = pastel.green(committer_relative.ljust(max_committer_relative_length))
  colored_authorname = pastel.blue(authorname.ljust(max_authorname_length))
  colored_objectname = pastel.red(objectname)
  colored_head = pastel.cyan(head)
  colored_subject = pastel.white(subject)
  colored_by = pastel.white('by')

  summary_detail = "#{colored_refname}   #{colored_committer_relative} #{colored_by} #{colored_authorname}   #{colored_objectname} #{colored_subject}"
  full_detail = "#{colored_head} #{colored_refname}\n      #{colored_committer_relative} #{colored_authorname}\n      #{colored_objectname} #{colored_subject}\n"

  branch_details[summary_detail] = { branch: branch, detail: full_detail }
end

# Ask the user to select a branch
selected_summary_detail = prompt.select("Select a branch:") do |menu|
  branch_details.each do |summary, details|
    menu.choice name: summary, value: details
  end
end

# Retrieve the selected branch from the hash
selected_branch = selected_summary_detail[:branch]
selected_detail = selected_summary_detail[:detail]

# Print the selected branch details
puts "You selected the branch: #{selected_branch.name}"
puts selected_detail

# Checkout the selected branch
repo.checkout(selected_branch.name)
puts "Checked out to branch: #{selected_branch.name}"

