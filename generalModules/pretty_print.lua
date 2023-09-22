local expect = require("cc.expect").expect
local util = require("generalModules.utilties").table
local function pretty_print(Tbl,spaces)
    expect(1,Tbl,"table")
    spaces = spaces or "\t"
    
end
return pretty_print