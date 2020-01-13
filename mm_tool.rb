#!/usr/bin/env ruby

###############################################################################
# mm_tool.rb
#  Run this script with `help` for more information (or examine this file.)
###############################################################################

require 'curses'  # Provides environment for this script.

# Curses.init_screen
# Curses.start_color if Curses.has_colors?
# 
# begin
#   nb_lines = Curses.lines
#   nb_cols = Curses.cols
# ensure
#   Curses.close_screen
# end
# 
# puts "Number of rows: #{nb_lines}"
# puts "Number of columns: #{nb_cols}"
# 
# Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLUE)
# # Curses.attrset(Curses.color_pair(1) | Curses::A_BLINK)
# Curses.addstr("Hello World")
# puts "done"


# Curses.init_screen
# Curses.start_color if Curses.has_colors?
# 
# Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLUE)
# 
# begin
#   x = Curses.cols / 2  # We will center our text
#   y = Curses.lines / 2
#   Curses.setpos(y, x)  # Move the cursor to the center of the screen
#   Curses.attrset(Curses.color_pair(1) | Curses::A_BLINK)
#   Curses.addstr("Hello World")  # Display the text
#   Curses.refresh  # Refresh the screen
#   Curses.getch  # Waiting for a pressed key to exit
# ensure
#   Curses.close_screen
# end
# 


Curses.init_screen
Curses.curs_set(0)  # Invisible cursor

# begin
#   # Building a static window
#   win1 = Curses::Window.new(Curses.lines / 2 - 1, Curses.cols / 2 - 1, 0, 0)
#   win1.box("o", "o")
#   win1.setpos(2, 2)
#   win1.addstr("Hello")
#   win1.refresh
# 
#   # In this window, there will be an animation
#   win2 = Curses::Window.new(Curses.lines / 2 - 1, Curses.cols / 2 - 1, 
#                             Curses.lines / 2, Curses.cols / 2)
#   win2.box("|", "-")
#   win2.refresh
#   2.upto(win2.maxx - 3) do |i|
#     win2.setpos(win2.maxy / 2, i)
#     win2 << "*"
#     win2.refresh
#     sleep 0.05 
#   end
# 
#   # Clearing windows each in turn
#   sleep 0.5 
#   win1.clear
#   win1.refresh
#   win1.close
#   sleep 0.5
#   win2.clear
#   win2.refresh
#   win2.close
#   sleep 0.5
# rescue => ex
#   Curses.close_screen
# end


win1 = Curses.stdscr.subwin(10, 20, 0, 0)
#   win1.box("|", "-")
  # The ACS_xxxx aren't included, so we will specify characters manually.
  win1.attron(Curses::A_ALTCHARSET)
  win1.box(120, 113)
  win1.attroff(Curses::A_ALTCHARSET)
  win1.refresh
  input = Curses.getstr
  
  
  
  
  

