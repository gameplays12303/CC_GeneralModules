local term = term
---@param Sx number
---@param sY number
---@param BC number
---@param TC number
return function (Sx,sY,BC,TC)
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
end