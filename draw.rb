#!/usr/bin/env ruby

require 'date'
require 'optparse'
require 'shellwords'

class GitHubContributionsArtDrawer
  class << self
    def run!(args)
      new(args).run!
    end
  end

  def initialize(args)
    @args     = args
    @input    = STDIN
    @output   = STDOUT
    @names    = Deque.new
    @emails   = Deque.new
    @messages = Deque.new
  end

  def run!
    parse_args!
    load_defaults!
    read_input!
    validate_input!
    write_output!
  end

  private

  def parse_args!
    parser = OptionParser.new do |o|
      o.banner = 'Usage:'
      o.separator "    #{$0} [options]"
      o.separator ''
      o.separator 'Options:'

      w = ->(s) do
        s.lstrip.lines.map.with_index do |line, idx|
          idx > 0 ? ' ' * 37 + line.strip : line.strip
        end.join("\n") + "\n\n"
      end

      h = <<-EOT
        Set input file.
        Default: STDIN.
      EOT
      o.on('-i INPUT', '--input=INPUT', w.(h)) do |v|
        @input = File.open(v, 'r')
      end
      h = <<-EOT
        Set output file.
        Default: STDOUT.
      EOT

      o.on('-o OUTPUT', '--output=OUTPUT', w.(h)) do |v|
        @output = File.open(v, 'w')
      end
      h = <<-EOT
        Set GIT_AUTHOR_NAME & GIT_COMMITTER_NAME.
        Allows multiple values.
        Default: `No One`.
      EOT

      o.on('-n NAME', '--name=NAME', w.(h)) do |v|
        @names.values << v
      end
      h = <<-EOT
        Set email for GIT_AUTHOR_EMAIL & GIT_COMMITTER_EMAIL.
        Allows multiple values.
        Default: `example@example.org`.
      EOT

      o.on('-e EMAIL', '--email=EMAIL', w.(h)) do |v|
        @emails.values << v
      end
      h = <<-EOT
        Set commit message.
        Allows multiple values.
        If prefixed with @, it will threat the argument as a file.
        Default: `@commit_messages.txt`.
      EOT

      o.on('-m MESSAGE', '--message=MESSAGE', w.(h)) do |v|
        if v.start_with?('@')
          @messages.values = File.read(v[1..-1]).lines.map(&:chomp)
        else
          @messages.values << v
        end
      end

      o.on_tail('-h', '--help', 'Print this message and exit.') do
        puts o
        exit
      end
    end

    @args = parser.parse!(@args)
  rescue OptionParser::InvalidOption => e
    STDERR.puts "#{$0}: #{e}"
    STDERR.puts
    STDERR.puts parser
    exit
  end

  def load_defaults!
    @names.values << 'No One' if @names.values.empty?
    @emails.values << 'example@example.org' if @emails.values.empty?
    @messages.values = File.read(File.expand_path('../commit_messages.txt', __FILE__)).lines.map(&:chomp) if @messages.values.empty?
  end

  def read_input!
    @source = @input.read
    @source = @source.lines.map{ |line| line.strip.gsub('|', '').chars }
  end

  def validate_input!
    raise 'source should not contain more than 7 lines' if @source.length > 7
    raise 'source lines differ in length' if @source.map(&:length).uniq.length != 1
    raise 'source contains lines longer than 52 chars' if @source.map.any?{ |line| line.length > 54 }
  rescue RuntimeError => e
    STDERR.puts "#{$0}: #{e}"
    exit
  end

  def write_output!
    @output.puts '#!/bin/sh'
    @output.puts

    @output.puts 'git add .'
    @output.puts

    today = Date.today
    end_of_last_week = today - today.wday
    beginning_of_graph_year = end_of_last_week - 52 * 7

    @source.each_with_index do |line, line_idx|
      line.each_with_index do |char, char_idx|
        count = char.to_i(36)

        if count > 0
          count.times do |minute|
            name = @names.next
            email = @emails.next
            message = @messages.next
            date = beginning_of_graph_year + char_idx * 7 + line_idx
            minute = '%02d' % minute
            s = []
            s << "GIT_AUTHOR_DATE=#{date.to_s}\\ 10:#{minute}:00"
            s << "GIT_COMMITTER_DATE=#{date.to_s}\\ 10:#{minute}:00"
            s << "GIT_AUTHOR_NAME=#{Shellwords.escape(name)}"
            s << "GIT_COMMITTER_NAME=#{Shellwords.escape(name)}"
            s << "GIT_AUTHOR_EMAIL=#{Shellwords.escape(email)}"
            s << "GIT_COMMITTER_EMAIL=#{Shellwords.escape(email)}"
            s << "git commit --allow-empty --allow-empty-message -m #{Shellwords.escape(message)}"
            @output.puts(s.join(' '))
          end
          @output.puts
        end
      end
    end
  end

  class Deque
    attr_accessor :values, :index

    def initialize(values = [], index = 0)
      @values, @index = values, index
    end

    def next
      if @index >= @values.length
        @index = 0
      end

      result = @values[@index]
      @index += 1
      result
    end
  end
end

if $0 == __FILE__
  GitHubContributionsArtDrawer.run!(ARGV)
end
