-- built to be a graphics module -- draw_assets and draw_imagess 

local expect = (require and require("cc.expect") or dofile("rom/modules/main/cc/expect.lua")).expect
local graphics = {}
---@overload fun(Table:table)
function graphics.draw_asset(Table)
    expect(1,Table,"table")
	local color = term.getBackgroundColor()
    for i,v in pairs(Table)do
        paintutils.drawImage(paintutils.loadImage(Table[i].path),Table[i].x,Table[i].y)
    end
	term.setBackgroundColor(color)
end
---@overload fun(r:number, x:number, y:number, c:number)
function graphics.drawCircle(r, x, y, c)
	expect(1,r,"number")
    expect(2,x,"number")
    expect(3,y,"number")
	local color = term.getBackgroundColor()
	local dX, dY, dYC = 0, 0, 0
	local cN = tonumber(c)
	while dY <= dX do
		dX = math.sqrt(r * r - dY * dY)
		dYC = dY / 1.5
		paintutils.drawPixel(x + dX, y - dYC, cN)
		paintutils.drawPixel(x + dX, y + dYC, cN)
		paintutils.drawPixel(x - dX, y - dYC, cN)
		paintutils.drawPixel(x - dX, y + dYC, cN)
		dY = dY + 1
	end
	dX, dY = 0, 0
	while dX <= dY do
		dY = math.sqrt(r * r - dX * dX)
		dYC = dY / 1.5
		paintutils.drawPixel(x + dX, y - dYC, cN)
		paintutils.drawPixel(x + dX, y + dYC, cN)
		paintutils.drawPixel(x - dX, y - dYC, cN)
		paintutils.drawPixel(x - dX, y + dYC, cN)
		dX = dX + 1
	end
	term.setBackgroundColor(color)
end
---@overload fun(x1:number,y1:number,x2:number,y2:number,color:number,filledBox:boolean)
function graphics.draw(x1,y1,x2,y2,color,filledBox)
    expect(1,x1,"number")
    expect(2,y1,"number")
    expect(3,x2,"number")
    expect(4,y2,"number")
    expect(5,color,"number")
    expect(6,filledBox,"boolean","nil")
	local oldColor = term.getBackgroundColor()
	if filledBox 
    then
        paintutils.drawFilledBox(x1,y1,x2,y2,color)
    else
        
		paintutils.drawBox(x1,y1,x2,y2,color)
    end
	term.setBackgroundColor(oldColor)
	os.sleep(10)
end
return graphics
