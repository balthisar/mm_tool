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


# Curses.init_screen
# Curses.curs_set(0)  # Invisible cursor

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


# win1 = Curses.stdscr.subwin(10, 20, 0, 0)
# #   win1.box("|", "-")
#   # The ACS_xxxx aren't included, so we will specify characters manually.
#   win1.attron(Curses::A_ALTCHARSET)
#   win1.box(120, 113)
#   win1.attroff(Curses::A_ALTCHARSET)
#   win1.setpos(1,1)
#   win1.addstr("Hello, world: ")
#   win1.setpos(2,1)
# #   win1.move(4,4)
#   win1.refresh
#   input = win1.getstr
#   win1.setpos(3,1)
#   win1.addstr("You entered #{input}")
#   win1.refresh
#   sleep 3
#   
#   

Curses.init_screen
Curses.cbreak
Curses.noecho
Curses.stdscr.keypad = true
at_exit do
  Curses.close_screen
end



menu = Curses::Menu.new([
  Curses::Item.new("Apple", "Red fruit"),
  Curses::Item.new("Orange", "Orange fruit"),
  Curses::Item.new("Banana", "Yellow fruit")
])
menu.post

while ch = Curses.getch
  begin
    case ch
    when Curses::KEY_UP, ?k
      menu.up_item
    when Curses::KEY_DOWN, ?j
      menu.down_item
    else
      break
    end
  rescue Curses::RequestDeniedError
  end
end

menu.unpost


# Curses.init_screen
# Curses.cbreak
# Curses.noecho
# Curses.stdscr.keypad = true
# at_exit do
#   Curses.close_screen
# end
# 
# fields = [
#   Curses::Field.new(1, 10, 4, 18, 0, 0),
#   Curses::Field.new(1, 10, 6, 18, 0, 0)
# ]
# fields.each do |field|
#   field.set_back(Curses::A_UNDERLINE)
#   field.opts_off(Curses::O_AUTOSKIP)
# end
# 
# form = Curses::Form.new(fields)
# form.post
# 
# Curses.setpos(4, 10)
# Curses.addstr("Value 1:")
# Curses.setpos(6, 10)
# Curses.addstr("Value 2:")
# 
# while ch = Curses.get_char
#   begin
#     case ch
#     when Curses::KEY_F1
#       break
#     when Curses::KEY_DOWN
#       form.driver(Curses::REQ_NEXT_FIELD)
#       form.driver(Curses::REQ_END_LINE)
#     when Curses::KEY_UP
#       form.driver(Curses::REQ_PREV_FIELD)
#       form.driver(Curses::REQ_END_LINE)
#     when Curses::KEY_RIGHT
#       form.driver(Curses::REQ_NEXT_CHAR)
#     when Curses::KEY_LEFT
#       form.driver(Curses::REQ_PREV_CHAR)
#     when Curses::KEY_BACKSPACE
#       form.driver(Curses::REQ_DEL_PREV)
#     else
#       form.driver(ch)
#     end
#   rescue Curses::RequestDeniedError
#   end
# end
# 
# form.unpost
# 



# def onsig(signal)
#   Curses.close_screen
#   exit signal
# end
# 
# def place_string(y, x, string)
#   Curses.setpos(y, x)
#   Curses.addstr(string)
# end
# 
# def cycle_index(index)
#   (index + 1) % 5
# end
# 
# %w[HUP INT QUIT TERM].each do |sig|
#   unless trap(sig, "IGNORE") == "IGNORE"  # previous handler
#     trap(sig) {|s| onsig(s) }
#   end
# end
# 
# Curses.init_screen
# Curses.nl
# Curses.noecho
# Curses.curs_set 0
# srand
# 
# xpos, ypos = {}, {}
# x_range = 2..(Curses.cols - 3)
# y_range = 2..(Curses.lines - 3)
# (0..4).each do |i|
#   xpos[i], ypos[i] = rand(x_range), rand(y_range)
# end
# 
# i = 0
# loop do
#   x, y = rand(x_range), rand(y_range)
# 
#   place_string(y, x, ".")
# 
#   place_string(ypos[i], xpos[i], "o")
# 
#   i = cycle_index(i)
#   place_string(ypos[i], xpos[i], "O")
# 
#   i = cycle_index(i)
#   place_string(ypos[i] - 1, xpos[i],      "-")
#   place_string(ypos[i],     xpos[i] - 1, "|.|")
#   place_string(ypos[i] + 1, xpos[i],      "-")
# 
#   i = cycle_index(i)
#   place_string(ypos[i] - 2, xpos[i],       "-")
#   place_string(ypos[i] - 1, xpos[i] - 1,  "/ \\")
#   place_string(ypos[i],     xpos[i] - 2, "| O |")
#   place_string(ypos[i] + 1, xpos[i] - 1, "\\ /")
#   place_string(ypos[i] + 2, xpos[i],       "-")
# 
#   i = cycle_index(i)
#   place_string(ypos[i] - 2, xpos[i],       " ")
#   place_string(ypos[i] - 1, xpos[i] - 1,  "   ")
#   place_string(ypos[i],     xpos[i] - 2, "     ")
#   place_string(ypos[i] + 1, xpos[i] - 1,  "   ")
#   place_string(ypos[i] + 2, xpos[i],       " ")
# 
#   xpos[i], ypos[i] = x, y
# 
#   Curses.refresh
#   sleep(0.5)
# end
