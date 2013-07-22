--[[	Foreman
		Usage: foreman <hmap> <x> <y> <z>]]--

oArgs = {...}
if #oArgs ~= 4 then
	print("Usage:")
	print("  foreman <hmap> <x> <y> <z>")
end

local aHmap,aX,aY,aZ,aF = unpack(oArgs)
local vCornerStone = vector.new(aX,aY,aZ)

-- Table to store heightmap
local oRelMap = nil
local oAbsMap = { }
local oWorkers = { }

if fs.exists(aHmap) then
	fHmap = fs.open(aHmap,"r")
	oRelMap = textutils.unserialize(fHmap.readAll())
	fHmap.close()

	local iEstBlk = 0 
	local maxX = 0
	local maxY = 0
	local maxZ = 0

	for n=1,#oRelMap do
		--estimate needed resources/dimensions
		iEstBlk = iEstBlk + oRelMap[n].y
		if oRelMap[n].x > maxX then maxX = oRelMap[n].x end
		if oRelMap[n].y > maxY then maxY = oRelMap[n].y end
		if oRelMap[n].z > maxZ then maxZ = oRelMap[n].z end	

		local tmpX=oRelMap[n].x
		local tmpZ=oRelMap[n].z
		
		oPoint = vector.new(oRelMap[n].x,oRelMap[n].y,oRelMap[n].z) + vCornerStone
		print(textutils.serialize(oPoint))
		if oPoint.y ~= 0 then
			table.insert(oPoint)
		end
	end

	print ("Dimensions: "..(maxX+1).."x"..(maxZ+1).."x"..(maxY + 1))
	print ("Estimated Required blocks: "..iEstBlk)

	--poll for clients
	oWorkers = RC.Poll({iType=RC.Types.Turtle})
	
else
	print("foreman: heightmap file not found")
end