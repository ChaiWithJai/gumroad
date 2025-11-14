#!/usr/bin/env ruby
# Script to generate a codebase rollup including infrastructure and important app code

require 'find'

OUTPUT_FILE = 'CODEBASE_ROLLUP.txt'

# Directories and files to include completely
INFRASTRUCTURE_FILES = [
  # Docker
  'docker/base/Dockerfile',
  'docker/base/Dockerfile.test',
  'docker/web/Dockerfile',
  'docker/web/Dockerfile.test',
  'docker/nginx/Dockerfile',
  'docker/branch_app_nginx/Dockerfile',
  'docker/docker-compose-local.yml',
  'docker/docker-compose-test-and-ci.yml',

  # CI/CD
  '.buildkite/pipeline.yml',
  '.github/workflows/tests.yml',
  '.github/workflows/autofix.yml',

  # Build & Deploy
  'Makefile',
  'Procfile.dev',

  # Package files
  'Gemfile',
  'package.json',

  # Ruby/Node version
  '.ruby-version',
  '.node-version',

  # Main config
  'config/application.rb',
  'config/database.yml',
  'config/mongoid.yml',
  'config/puma.rb',
  'config/shakapacker.yml',
  'config/sidekiq_schedule.yml',
  'config/anycable.yml',
  '.env.example',

  # Key initializers
  'config/initializers/cors.rb',
  'config/initializers/flipper.rb',
  'config/initializers/redis.rb',
  'config/initializers/sidekiq.rb',
  'config/initializers/stripe.rb',
]

# Buildkite scripts
BUILDKITE_SCRIPTS_DIR = '.buildkite/scripts'

# Directories to list (show structure but not full content)
APP_DIRECTORIES = [
  'app/controllers',
  'app/models',
  'app/services',
  'app/javascript/components',
  'app/javascript/pages',
  'app/views',
  'lib',
]

def write_separator(f, title)
  f.puts "\n#{'=' * 80}"
  f.puts "# #{title}"
  f.puts "#{'=' * 80}\n\n"
end

def write_file_content(f, filepath)
  return unless File.exist?(filepath)

  f.puts "## File: #{filepath}"
  f.puts "```"
  f.puts File.read(filepath)
  f.puts "```"
  f.puts "\n"
rescue => e
  f.puts "Error reading #{filepath}: #{e.message}\n\n"
end

def list_directory_structure(f, dir, max_depth = 3)
  return unless File.directory?(dir)

  f.puts "## Directory Structure: #{dir}\n\n"

  files = []
  Find.find(dir) do |path|
    relative_path = path.sub("#{dir}/", '')
    depth = relative_path.count('/')

    # Skip deep nesting
    if depth > max_depth
      Find.prune
      next
    end

    # Skip certain directories
    if File.directory?(path) && File.basename(path).match?(/^(node_modules|tmp|log|vendor|\.git)$/)
      Find.prune
      next
    end

    files << relative_path if File.file?(path)
  end

  files.sort.each do |file|
    f.puts "  - #{file}"
  end

  f.puts "\n"
rescue => e
  f.puts "Error listing #{dir}: #{e.message}\n\n"
end

# Generate the rollup
File.open(OUTPUT_FILE, 'w') do |f|
  f.puts "GUMROAD CODEBASE ROLLUP"
  f.puts "Generated: #{Time.now}"
  f.puts "=" * 80
  f.puts "\nThis file contains the infrastructure, configuration, and structure of the Gumroad codebase."
  f.puts "\n"

  # Infrastructure & Deployment
  write_separator(f, "INFRASTRUCTURE & DEPLOYMENT FILES")

  INFRASTRUCTURE_FILES.each do |filepath|
    write_file_content(f, filepath)
  end

  # Buildkite scripts
  if File.directory?(BUILDKITE_SCRIPTS_DIR)
    Dir.glob("#{BUILDKITE_SCRIPTS_DIR}/*").sort.each do |script|
      write_file_content(f, script)
    end
  end

  # Application Structure
  write_separator(f, "APPLICATION CODE STRUCTURE")

  APP_DIRECTORIES.each do |dir|
    list_directory_structure(f, dir)
  end

  # Database schema summary
  write_separator(f, "DATABASE SCHEMA")
  if File.exist?('db/schema.rb')
    f.puts "## File: db/schema.rb (first 500 lines - full file is #{File.readlines('db/schema.rb').count} lines)"
    f.puts "```"
    f.puts File.readlines('db/schema.rb').first(500).join
    f.puts "... [truncated - see db/schema.rb for complete schema]"
    f.puts "```"
    f.puts "\n"
  end

  # Routes summary
  write_separator(f, "ROUTES")
  if File.exist?('config/routes.rb')
    f.puts "## File: config/routes.rb (first 200 lines - full file is #{File.readlines('config/routes.rb').count} lines)"
    f.puts "```"
    f.puts File.readlines('config/routes.rb').first(200).join
    f.puts "... [truncated - see config/routes.rb for complete routes]"
    f.puts "```"
    f.puts "\n"
  end

  # Key initializers list
  write_separator(f, "ALL INITIALIZERS")
  if File.directory?('config/initializers')
    f.puts "Complete list of initializers:\n\n"
    Dir.glob('config/initializers/*.rb').sort.each do |init|
      f.puts "  - #{init}"
    end
    f.puts "\n"
  end
end

puts "Rollup generated: #{OUTPUT_FILE}"
puts "Size: #{File.size(OUTPUT_FILE)} bytes"
