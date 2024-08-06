---@diagnostic disable: undefined-field, redundant-parameter, need-check-nil
local term = term
---@param Sx number|nil
---@param sY number|nil
---@param BC number|nil
---@param TC number|nil
---@param mon terminal|table|nil
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