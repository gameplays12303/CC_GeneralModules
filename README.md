# CC_GeneralModules
this contain some general modules i made for a OS i desinged these should work with CraftOs as well as they are meant to be basic (Free to Use)
note: files located under notMine are not my creation and are under the lisense terms of their creator written inside the modules

#### not_mine:

db_Protect.lua, no documentation

#### utilties: 

bush of general purpose functions 
 
i either didn't want people to be confused with or just really had no place to go

#### mRequire: 

a modified version of require (meant for development) 

unlike normal require it dose not have a loop stuck problem and the function can be reloaded

#### logs: 

self_explained (a log handling system)

#### input: 

basic terminal input and output tools


#### fm: 

stands for file manager it's design to open,write and close a file it's not very efficient if you are writing to a file multiple times in a row

#### file_select:

is a file_select explorer uses the input module

#### expect2:

designed to handle more then the original expect api can it also upgrades many check functions within

#### clear:

just clears the terminal and sets the text and background color (if it's been given)

#### GUI/GUI:

a module containing a new windowing system yes it's a bet unrealistic but i wanted to make sure you understood what window what being used for what

why is it more form then function is because it breaks the native into a terminal only with no text 

#### GUI/file_select: 

another one yes this dose the same thing expect it uses the new windowing system

##### apis/Tbl_protect: 

builds in a metaData system protection 

warning using of this will not break CraftOS but it will do damage if you protect a table that CraftOS isn't expecting to be protected
