#!/usr/bin/env ruby
require "sqlite3"

PROGRAM_NAME = "sticky"

DIR = ENV['XDG_CONFIG_HOME'] + "/#{PROGRAM_NAME}"
NOTES_DIR = "#{DIR}/notes"
NOTES_DB = "#{DIR}/notes.db"

OPTIONS = %w[New List Delete Quit]
EDITOR = ENV['EDITOR'] or "vi"

GREEN = "\033[22;32m"
BOLD = "\033[01;37m"
GRAY = "\033[00;37m"
RESET = "\033[0m"

def title
  print "["
  OPTIONS.each do |option|
    print RESET + option[0]
    print GRAY + "-" + option
    if not option == OPTIONS.last
      print " "
    else
      puts "]"
    end
  end
end

def prompt
  print GRAY
  print "> "
  print RESET
  user = gets.chomp

  if user.empty?
    raise IOError
  else
    return user
  end
end

def escape_data(note)
  note = note.gsub("'", "\\\\'")
  note = note.gsub('"', '\"')
  note = note.gsub(" ", "\\ ")

  return note
end

def store_note_name(note_name)
  file = File.open(NOTE_DAT, "a")
  file.puts(note_name)
  file.close
end

def new_note
  puts "Enter note's name"

  begin
    note_name = prompt
  rescue IOError
    warn "Note's name is empty, ignoring"
    return
  end

  note_name_path = "#{NOTES_DIR}/#{note_name}"

  if note_name.length > 255
    warn "Note name is too long"
    return
  end

  system("#{EDITOR} #{escape_data(note_name_path)}")

  if File.exists?(note_name_path)
    if not File.zero?(note_name_path)
      store_note_name(note_name)
    else
      warn "#{note_name} is empty, not saving"
      File.delete(note_name_path)
    end
  else
    warn "#{note_name} not saved, ignoring"
    return
  end
end

def open_note(c)
  if File.exists?(NOTE_DAT)
    file = File.open(NOTE_DAT, "r")
    notes = file.read.split("\n")
    file.close
  else
    abort "Error reading '#{NOTE_DAT}'"
  end

  if c >= notes.length or c < 0
    puts "Invalid input"
    return
  end


  system("#{EDITOR} #{NOTES_DIR}/#{escape_data(notes[c])}")
end

def list_notes
  db = SQLite3::Database.new(NOTES_DB)
  db.results_as_hash = true

  db.execute("CREATE TABLE IF NOT EXISTS notes (
             id INTEGER PRIMARY KEY, 
             name TEXT
            )")

  notes = db.execute("SELECT * FROM notes")
  db.close

  if notes.empty?
    puts "You do not have any notes!"
    return
  end

  notes.each do |note|
    puts "#{GREEN}#{note['id']}#{RESET} #{note['name']}"
  end
end

def delete_note
  puts "Enter note's number"

  begin
    c = prompt.to_i
  rescue
    puts "Invalid input"
    return
  end

  file = File.open(NOTE_DAT, "r")
  notes = file.read.split("\n")
  file.close

  if c >= notes.length or c < 0
    puts "Invalid input"
    return
  end

  File.delete("#{NOTES_DIR}/#{notes[c]}")

  notes.delete_at(c)

  file = File.open(NOTE_DAT, "w")
  notes.each do |note|
    file.puts(note)
  end
  file.close
end

### MAIN ###

if not File.directory?(DIR)
  Dir.mkdir(DIR)
end

if not File.directory?(NOTES_DIR)
  Dir.mkdir(NOTES_DIR)
end

if not File.exists?(NOTES_DB)
  File.open(NOTES_DB, "w") {}
end

first = true
while true do
  if first
    list_notes
    puts
    first = false
  end

  title

  begin
    c = prompt.downcase
  rescue IOError
    puts
    next
  end

  case c
  when /^[0-9]+$/
    open_note(c.to_i)
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
end
