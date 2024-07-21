#!/usr/bin/env ruby

#!/usr/bin/env ruby

require 'rugged'
require 'tty-prompt'
require 'pastel'

def valid_oid?(oid)
  !!(oid =~ /\A[0-9a-f]{40}\z/)
end

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

# Open the repository from the current working directory
begin
  repo_path = Dir.pwd
  repo = Rugged::Repository.discover(repo_path)
rescue Rugged::RepositoryError => e
  puts "Error: #{e.message}"
  exit 1
end

# Fetch local and remote branches
branches = repo.branches.each(:local).to_a + repo.branches.each(:remote).to_a

# Fetch commit times for sorting
branch_commits = branches.map { |branch| [branch, repo.lookup(branch.target_id)] }

# Sort branches by committer date
branch_commits.sort_by! { |branch, commit| -commit.time.to_i }

# Initialize TTY Prompt and Pastel for coloring
prompt = TTY::Prompt.new
pastel = Pastel.new

# Define a hash to store branch details for selection
branch_details = {}

# Calculate the maximum lengths for formatting
max_branch_name_length = branches.map { |branch| branch.name.length }.max
max_committer_relative_length = branch_commits.map { |_, commit| time_ago_in_words(commit.time).length }.max
max_author_name_length = branch_commits.map { |_, commit| commit.author[:name].length }.max

# Loop through each branch and store the details in the hash
branch_commits.each do |branch, commit|
  head = branch.head? ? '*' : ' '
  branch_name = branch.name
  committer_relative = time_ago_in_words(commit.time)
  author_name = commit.author[:name]
  object_name = commit.oid[0..6]
  subject = commit.message.split("\n").first

  # Color each part individually
  colored_branch_name = pastel.yellow(branch_name.ljust(max_branch_name_length))
  colored_committer_relative = pastel.green(committer_relative.ljust(max_committer_relative_length))
  colored_author_name = pastel.blue(author_name.ljust(max_author_name_length))
  colored_object_name = pastel.red(object_name)
  colored_head = pastel.cyan(head)
  colored_subject = pastel.white(subject)
  colored_by = pastel.white('by')

  summary_detail = "#{colored_branch_name}   #{colored_committer_relative} #{colored_by} #{colored_author_name}   #{colored_object_name} #{colored_subject}"
  full_detail = "#{colored_head} #{colored_branch_name}\n      #{colored_committer_relative} #{colored_author_name}\n      #{colored_object_name} #{colored_subject}\n"

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

# Checkout the selected branch
repo.checkout(selected_branch.name)
puts "Checked out branch #{selected_branch.name}"
