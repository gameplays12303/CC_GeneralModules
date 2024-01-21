---@diagnostic disable: undefined-field, redundant-parameter, need-check-nil
local term = term
---@param Sx number
---@param sY number
---@param BC number
---@param TC number
---@param mon terminal|table
return function (Sx,sY,BC,TC,mon)
    local current = term.current()
    term.redirect(mon or current)
    if BC
    then
        term.setBackgroundColor(BC)
    end
    if TC
    then
        term.setTextColor(TC)
    end
    term.clear()
    term.setCursorPos(Sx or 1,sY or 1)
    term.redirect(current)
end