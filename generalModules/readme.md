notice documentation will not be here for files not my own

not_mine : db_Protect.lua,

utilities: bush of general purpose functions 
    i either didn't want people to be confused with or just really had no place to go

mRequire: a modified version of require (meant for development ) 
    unlike normal require it dose not have a loop stuck problem and the function can be reloaded

logs: self_explained (a log handling system)

input: basic terminal input and output tools


fm : stands for file manager it's design to open,write and close a file it's not very efficient if you are writing to a file multiple times in a row

file_select: is a file_select explorer uses the input module

expect2: designed to handle more then the original expect api can it also upgrades many check functions within

clear: just clears the terminal and sets the text and background color (if it's been given)

GUI/GUI: a module containing a new windowing system yes it's a bet unrealistic but i wanted to make sure you understood what window what being used for what
why is it more form then function is because it breaks the native into a terminal only with no text 
        for textBox:Chat_Box , we have in configuration: default_BackgroundColor,default_TextColor,AutoComplete_BackgroundColor
        AutoComplete_TextColor,disableNewLine,AutoComplete
        you will put what you want in the 2nd argument as a table with key based indexing 
        for autoComplete we do accept functions or a table or nether (disabled) 



GUI/file_select: another one yes this dose the same thing expect it uses the new windowing system

apis/Tbl_protect builds in a metaData system protection 
    warning using of this will not break CraftOS but it will do damage if you protect a table that CraftOS isn't expecting to be protected

Class -- requires the dbprotect 