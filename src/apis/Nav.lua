iFace = 1
eFace = { North = 2, East = 3, South = 0, West = 1}
eShift = { North = vector.new(0,0,1), East = vector.new(-1,0,0), South = vector.new(0,0,-1), West = vector.new(1,0,0)}
bDebug = false
 
function Calibrate ()
	if turtle == nil then
		return false
	end
	vOrigin = vector.new(gps.locate())
	f = 0
	while not turtle.forward() and f < 4 do
		Nav.TurnRight()
		f = f + 1
	end
	 
	if f == 5 then
	  return false
	else
		--calculate facing and store
		vPos = vector.new(gps.locate())
		vShift = textutils.serialize(vOrigin - vPos)
		turtle.back()
 
		if vShift == textutils.serialize(eShift.North) then Nav.iFace = eFace.North
		elseif vShift == textutils.serialize(eShift.East) then Nav.iFace = eFace.East
		elseif vShift == textutils.serialize(eShift.South) then Nav.iFace = eFace.South
		elseif vShift == textutils.serialize(eShift.West) then Nav.iFace = eFace.West
		else return false end
 
		for y=2,f do TurnLeft() end
		return true
	end
end
 
function To(vCoord)
	if Nav.bDebug then print("Nav.To("..textutils.serialize(vCoord)..")") end
	vPos = vector.new(gps.locate())

	if vPos.y < vCoord.y then	MoveToY(vCoord.y) end
	MoveToX(vCoord.x)
	MoveToZ(vCoord.z)
	if vPos.y > vCoord.y then MoveToY(vCoord.y) end

	if vCoord.f ~= nil then 
		TurnTo(vCoord.f)
	end
end
 
function MoveZX(n)
 if Nav.bDebug == true then
	print("MoveZX "..n.. "("..Nav.iFace..")")
 end
   
	if n > 0 then
	for x = 1,n do
		turtle.forward()
	end
	elseif n < 0 then
		for x = -1,n,-1 do
			turtle.back()
		end
	end
end
 
function MoveY(n)
	if Nav.bDebug == true then
		print("MoveY "..n)
	end
	if n > 0 then
		for x = 1,n do
			turtle.up()
		end
	elseif n < 0 then
		for x = -1,n,-1 do
			turtle.down()
		end
	end
end

function MoveToX(n)
	 vOrigin = vector.new(gps.locate())
	 TurnTo(eFace.East)
	 d = n - vOrigin.x
	 MoveZX(d)
end

function MoveToY(n)
	 vOrigin = vector.new(gps.locate())
	 d = n - vOrigin.y
	 MoveY(d)
end

function MoveToZ(n)
	 vOrigin = vector.new(gps.locate())
	 TurnTo(eFace.South)
	 d = n - vOrigin.z
	 MoveZX(d)
end

function TurnTo(n)
	while n > 3 do
		n = n - 4
	end
	while n < 0 do
		n = n + 4
	end

	local i = math.abs(Nav.iFace - n)
	if Nav.iFace < n and i == 3 then
		while Nav.iFace ~= n do TurnLeft() end
	elseif Nav.iFace > n and i == 3 then
		while Nav.iFace ~= n do TurnRight() end
	elseif Nav.iFace < n then
		while Nav.iFace ~= n do TurnRight() end
	elseif Nav.iFace > n then
		while Nav.iFace ~= n do TurnLeft() end
	end
end
 
function TurnRight()
	turtle.turnRight()
	Nav.iFace = Nav.iFace+1
	if Nav.iFace == 4 then Nav.iFace = 0 end
end
 
function TurnLeft()
	turtle.turnLeft()
	Nav.iFace = Nav.iFace-1
	if Nav.iFace == -1 then Nav.iFace = 3 end
end