local term = term
---@overload fun(BC:number,TC:number)
return function (BC,TC)
    if BC
    then
        term.setBackgroundColor(BC)
    end
    if TC
    then
        term.setTextColor(TC)
    end
    term.clear()
    term.setCursorPos(1,1)
end