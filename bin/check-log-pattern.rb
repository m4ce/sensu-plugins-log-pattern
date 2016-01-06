#!/usr/bin/env ruby
#
# check-log-pattern.rb
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

require 'sensu-plugin/check/cli'
require 'fileutils'
require 'digest/md5'

class CheckLogPattern < Sensu::Plugin::Check::CLI
  option :source,
         :description => "Defines the log source (default: file)",
         :short => "-s <file>",
         :long => "--source <file>",
         :in => ["file"],
         :default => "file",
         :required => true

  option :file,
         :description => "Comma separated list of files (including globs) where pattern will be searched",
         :short => "-f <PATH>",
         :long => "--file <PATH>",
         :proc => proc { |s| s.split(',') },
         :default => []

  option :pattern,
         :description => "Comma separated list of patterns to search for",
         :short => "-p <PATTERN>",
         :long => "--pattern <PATTERN>",
         :proc => proc { |s| s.split(',') },
         :required => true

  option :ignore_pattern,
         :description => "Comma separated list of patterns to ignore",
         :short => "-i <PATTERN>",
         :long => "--ignore-pattern <PATTERN>",
         :proc => proc { |s| s.split(',') },
         :default => []

  option :state_dir,
         :description => "State directory",
         :long => "--state-dir <PATH> (default: /var/cache/check-log-pattern)",
         :default => "/var/cache/check-log-pattern"

  option :ignore_case,
         :description => "Ignore case sensitive",
         :long => "--ignore-case",
         :boolean => true,
         :default => false

  option :print_matches,
         :description => "Print log lines that match patterns",
         :long => "--print-matches",
         :boolean => true,
         :default => false

  option :warn,
         :description => "Warning if number of matches exceeds COUNT (default: 1)",
         :short => "-w <COUNT>",
         :long => "--warn <COUNT>",
         :default => 1

  option :crit,
         :description => "Critical if number of matches exceeds COUNT",
         :short => "-c <COUNT>",
         :long => "--crit <COUNT>",
         :default => nil

  def initialize()
    super

    @files = []

    case config[:source]
      when "file"
        raise "Must specify one or more files with the --file command line option when source is file" unless config[:file].size > 0

        # determine list of files
        config[:file].each do |file|
          @files += Dir.glob(file)
        end
    end

    raise "Warning threshold must be lower than the critical threshold" if (config[:crit] != nil and config[:warn] > config[:crit])

    # prepare state directory
    FileUtils.mkdir_p(config[:state_dir]) unless File.directory?(config[:state_dir])
  end

  def run
    case config[:source]
      when "file"
        problems = 0
        matches = {}

        @files.each do |file|
          hash = Digest::MD5.hexdigest("#{file}_#{config[:pattern]}")
          cursor_file = config[:state_dir] + "/" + hash + ".last_cursor"

          if File.exists?(cursor_file)
            last_cursor = File.read(cursor_file).chomp.to_i
          else
            last_cursor = 0
          end

          fd = File.open(file)
          fd.seek(last_cursor, File::SEEK_SET) if last_cursor > 0
          bread = 0
          fd.each_line do |line|
            bread += line.bytesize

            str = config[:ignore_case] ? line.downcase : line

            config[:ignore_pattern].each do |pattern|
              next if match = str.match(pattern)
            end

            config[:pattern].each do |pattern|
              if match = str.match(pattern)
                matches[pattern] ||= {}
                matches[pattern][file] ||= []
                matches[pattern][file] << line
                problems += 1
              end
            end
          end

          # update cursor file
          File.open(cursor_file, 'w') { |f| f.write(last_cursor + bread) }
        end

        msg = []
        bottom = []

        matches.each do |pattern, files|
          files.each do |file, lines|
            msg << "#{lines.size} lines matching '#{pattern}' in #{file}"

            if config[:print_matches]
              bottom << "  Lines matching '#{pattern}' in #{file}:"
              lines.each do |line|
                bottom << "    * #{line.chomp}"
              end
              bottom << ""
            end
          end
        end

        msg << "\n\n" if config[:print_matches]

        if config[:crit]
          critical("Found " + msg.join(', ') + bottom.join("\n")) if problems > config[:crit]
        end
        warning("Found " + msg.join(', ') + bottom.join("\n")) if problems > config[:warn]
        ok("Found no lines matching '#{config[:pattern].join(', ')}'")
    end
  end
end
