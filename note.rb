#!/usr/bin/env ruby

DIR = ENV['XDG_CONFIG_HOME'] + "/rbnote/"
NOTES_DIR = "#{DIR}/notes"
NOTE_DAT = "#{DIR}/notes.dat"

OPTIONS = %w[New List Delete Quit]
EDITOR = ENV['EDITOR'] or "vi"

GREEN = "\033[22;32m"
BOLD = "\033[01;37m"
RESET = "\033[00;37m"

def title
  print "["
  OPTIONS.each do |option|
    print BOLD + option[0]
    print RESET + "-" + option
    if not option == OPTIONS.last
      print " "
    else
      puts "]"
    end
  end
end

if not File.directory?(DIR)
  Dir.mkdir(DIR)
end

if not File.directory?(NOTES_DIR)
  Dir.mkdir(NOTES_DIR)
end

first = true
while true do
  title

  c = gets.chomp.downcase

  case c
  when /[0-9]/
    open_note c
  when "n"
    new_note
  when "l"
    list_notes
  when "d"
    delete_note
  when "q"
    exit
  else
    puts "Unknown command"
  end

  puts

  first = false
end