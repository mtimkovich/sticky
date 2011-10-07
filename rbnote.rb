#!/usr/bin/env ruby

DIR = ENV['XDG_CONFIG_HOME'] + "/rbnote"
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

def prompt
  print "> "
  user = gets.chomp

  if user.empty?
    raise IOError
  else
    return user
  end
end

def escape_data(note)
  note = note.sub("'", "\\\\'")
  note = note.sub('"', '\"')
  note = note.sub(" ", "\\ ")
  note = note.sub("\\", "\\\\\\\\\\")

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
  if File.exists?(NOTE_DAT)
    file = File.open(NOTE_DAT, "r")
    notes = file.read.split("\n")
    file.close
  else
    puts "Note not saved, ignoring"
  end

  if File.zero?(NOTE_DAT)
    puts "You do not have any notes!"
  end

  notes.each_index do |i|
    puts "#{GREEN}#{i}#{RESET} #{notes[i]}"
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
