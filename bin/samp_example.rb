#!/usr/bin/env ruby

require "ncursesw"


# begin
#   # initialize ncurses
#   Ncurses.initscr
#   Ncurses.cbreak           # provide unbuffered input
#   Ncurses.noecho           # turn off input echoing
#   Ncurses.nonl             # turn off newline translation
#   Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
#   Ncurses.stdscr.keypad(true)     # turn on keypad mode
#   
#   Ncurses::MENU.new([Ncurses::ITEM.new()])
#   
# 
#   Ncurses.stdscr.addstr("Press a key to continue") # output string
#   Ncurses.stdscr.getch                             # get a charachter
# 
#   moving(Ncurses.stdscr) # demo of moving cursor
#   border(Ncurses.stdscr) # demo of borders
#   two_borders()          # demo of two windows with borders
# 
# ensure
#   Ncurses.echo
#   Ncurses.nocbreak
#   Ncurses.nl
#   Ncurses.endwin
# end
# 


Ncurses.initscr
Ncurses.cbreak
Ncurses.noecho
Ncurses.stdscr.keypad(true)
at_exit do
  Ncurses.endwin
end



menu = Ncurses::Menu.new_menu([
  Ncurses::Menu::ITEM.new("Apple", "Red fruit"),
  Ncurses::Menu::ITEM.new("Orange", "Orange fruit"),
  Ncurses::Menu::ITEM.new("Banana", "Yellow fruit")
])

menu.post



while ch = Ncurses.stdscr.getch
  begin
    case ch
    #when Ncurses::KEY_UP, ?k
    when Ncurses::KEY_UP
      menu.menu_driver(Ncurses::Menu::REQ_UP_ITEM)
    #when Ncurses::KEY_DOWN, ?j
    when Ncurses::KEY_DOWN
      menu.menu_driver(Ncurses::Menu::REQ_DOWN_ITEM)
    else
      break
    end
  #rescue Ncurses::RequestDeniedError
  end
end

menu.unpost