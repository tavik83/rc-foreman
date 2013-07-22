if guid == nil then
   os.loadAPI("/apis/guid")
end
if Nav == nil then
   os.loadAPI("/apis/Nav")
   Nav.Calibrate()
end
 
Types = { Computer = 1, Turtle = 2, Miner = 4, Farmer = 8, Logger = 16, Digger = 32, Crafty = 64, Melee = 128 }
Cfg = { }
Version = -0.45
oWorkQueue = { }
oCurrentJob = nil
oRequests = { }
 
local function open()
  local bOpen, sFreeSide = false, nil
  for n,sSide in pairs(rs.getSides()) do  
    if peripheral.getType( sSide ) == "modem" then
      sFreeSide = sSide
      if rednet.isOpen( sSide ) then
        bOpen = true
        break
      end
    end
  end
 
  if not bOpen then
    if sFreeSide then
      print( "No modem active. Opening "..sFreeSide.." modem" )
      rednet.open( sFreeSide )
      return true
    else
      print( "No modem attached" )
      return false
    end
  end
  return true
end
 
function Init()
  if fs.exists("/etc/rc.cfg") then
    local fCfg = fs.open("/etc/rc.cfg","r")
    RC.Cfg = textutils.unserialize(fCfg.readLine())
    fCfg.close()
  else
    local fCfg = fs.open("/etc/rc.cfg","w")
    while iPrompt == nil or iPrompt < 1 or iPrompt > 8 do
      print("RC first run setup, please select client type:")
      print("1) Computer")
      print("2) Turtle")
      print("3) Mining Turtle")
      print("4) Farming Turtle")
      print("5) Logging Turtle")
      print("6) Digging Turtle")
      print("7) Crafty Turtle")
      print("8) Melee Turtle")
      io.write(">")
      iPrompt = tonumber(read())
    end
    iPrompt = 2 ^ (iPrompt - 1)
    RC.Cfg.Type = iPrompt
    fCfg.write(textutils.serialize(RC.Cfg))
    fCfg.close()
  end
end
 
function Listen()
  if open() then
    while true do
      local e,id,p,distance = os.pullEvent("rednet_message")
      if p:sub(1,3) == "rc:" then
        oPacket = textutils.unserialize(p:sub(4))
     
        --[[ Poll request handling ]]
        if oPacket.sCmd == "poll" then
          local oResp = { sCmd = "polr", sReqId = oPacket.sReqId, iType = RC.Cfg.Type, sLabel=os.getComputerLabel(), vGps = vector.new(gps.locate()), iVersion = RC.Version }
          Send(id,oResp)

        --[[ Job Request handling
            Job flow: 
                1) "jbr" job request received
                2) respond with "jba" job acknowledgement, with current workload
                3) when job started, notify requester with "jbs" job started packet
                4) when job completed, notify request with "jbc" job completed packet
            
            receiving "jba", "jbs", and "jbc" packets fires "job" events which can be pulled with

            event,iClientId,sReqId,sStatus = os.pullEvent("job")
         ]]
        elseif oPacket.sCmd == "jbr" then
          local oResp = { sCmd = "jba", sReqId = oPacket.sReqId, iJobsPending = #RC.oWorkQueue }
          Send(id,oResp)
          oPacket.Id = id
          table.insert(RC.oWorkQueue, oPacket)
          parallel.waitForAny(Listen, work)
        elseif oPacket.sCmd == "jba" then
          if oRequests[oPacket.sReqId] ~= nil then
            oRequests[oPacket.sReqId].sStatus = "acknowledged"
            os.queueEvent("job",id,oPacket.sReqId,"acknowledged")
          end
        elseif oPacket.sCmd == "jbs" then
          if oRequests[oPacket.sReqId] ~= nil then
            oRequests[oPacket.sReqId].sStatus = "running"
            os.queueEvent("job",id,oPacket.sReqId,"running")
          end
        elseif oPacket.sCmd == "jbc" then
          if oRequests[oPacket.sReqId] ~= nil then
            oRequests[oPacket.sReqId].sStatus = "completed"
            os.queueEvent("job",id,oPacket.sReqId,"completed",oPacket.iBlocksLeft)
          end


        --[[ File transfer request handling ]]
        elseif oPacket.sCmd == "fget" then
          if fs.exists(oPacket.sSrc) then
            fG = fs.open(oPacket.sSrc, "r")
            sContent = fG.readAll()
            fG.close()
            sCmd = "sok" -- success response
          else
            sContent = "File Not Found"
            sCmd = "serr"
          end
          local oResp = {sCmd=sCmd, sReqId=oPacket.sReqId, sContent=sContent}
          Send(id,oResp)
        elseif oPacket.sCmd == "fput" then
          if fs.exists(oPacket.sDest) == false then
            fP = fs.open(oPacket.sDest,"w")
            fP.write(oPacket.sContent)
            fP.close()
            sContent = "Successful File Copy"
            sCmd = "sok" -- success response
          else
            sContent = "File already exists"
            sCmd = "serr"
          end
          local oResp = {sCmd=sCmd,sReqId=oPacket.sReqId,sContent=sContent}
          Send(id,oResp)
        end
      end
    end
  end
end
 
--[[ work queue for jobs that block execution ]]
function work()
  if RC.bWorking == true then
    return
  end
  while #RC.oWorkQueue > 0 do
    RC.bWorking = true
    RC.oCurrentJob = RC.oWorkQueue[1]
    if RC.Cfg.bDebug == true then  
      print(textutils.serialize(RC.oWorkQueue))
    end
 
    --notify requester that job has started
    oPacket = { sCmd="jbs",sReqId=RC.oCurrentJob.sReqId }
    Send(RC.oCurrentJob.Id,oPacket)
 
    --if job contains starting point, navigate to it
    if RC.oCurrentJob.vCoords ~= nil then Nav.To(RC.oCurrentJob.vCoords) end
 
    oArgs = { }
    for sArg in string.gmatch(RC.oCurrentJob.sApp.." ", "%S+") do
      table.insert(oArgs, sArg)
    end
    os.run({},unpack(oArgs))
   
    if RC.Cfg.iIdle ~= nil and RC.oCurrentJob.bStandby ~= true then Nav.MoveToY(RC.Cfg.iIdle) end
 
    --notify requester of job completion
    oPacket.sCmd = "jbc"
    
    oPacket.iBlocksLeft = 0
    if turtle then
      for x = 1,16 do
        oPacket.iBlocksLeft = oPacket.iBlocksLeft + turtle.getItemCount(x)
      end
    end

    Send(RC.oCurrentJob.Id,oPacket)
    table.remove(RC.oWorkQueue,1)
    RC.oCurrentJob = nil
    os.sleep(.1)
  end
  RC.bWorking = false
end
 
function Send(Id,oPacket)
  rednet.send(Id,"rc:"..textutils.serialize(oPacket))
end
 
function Broadcast(oPacket)
  rednet.broadcast("rc:"..textutils.serialize(oPacket))
end
 
function JobRequest(sApp,vCoords)
  oPacket = { sCmd="jbr",sApp=sApp,sReqId=guid.generate(8) }
  oRequests[oPacket.sReqId] = oPacket
  if vCoords ~= nil then oPacket.vCoords=vCoords end
  return oPacket
end
 
 
--[[ Poll for nearby clients, returning a table of targets that pass the
     following optional filters:
        MaxD: Maximum distance from client
        MinD: Minimum disance from client
        Type: Computer, Turtle, Mining Turtle, Digging Turtle, Farming Turtle
]]
function Poll(oParams)
  sJobId = guid.generate(8)
  oClients = { }
  if oParams == nil then oParams = { } end
  oPacket = { sCmd="poll",sReqId=sJobId }
  Broadcast(oPacket)
 
  pollWait = function()
    while true do
      e,id,p,d = os.pullEvent("rednet_message")
      if p:sub(1,3) == "rc:" then                    
        oResp = textutils.unserialize(p:sub(4))
        oResp.Id = id
        if oResp.sCmd == "polr" and oResp.sReqId == sJobId then
          bPass = true
          --Type Filter
          if oParams.iType ~= nil then bPass = (oResp.iType == oParams.iType) end
           --Min Distance
          if oParams.MinD ~= nil then bPass = (bPass and oParams.MinD <= d) end
          --Max Distance
          if oParams.MaxD ~= nil then bPass = (bPass and oParams.MaxD >= d) end
          if bPass then table.insert(oClients,oResp) end
        end
      end
    end
  end
  parallel.waitForAny(timeout, pollWait)
  return oClients
end
 
function FPut(Id,sSrc,sDest)
  if Id == nil or sSrc == nil or fs.exists(sSrc) == false then return false end
  if sDest == nil then sDest = sSrc end
 
  fP = fs.open(sSrc,"r")
  sContent = fP.readAll()
  fP.close()
 
  sJobId = guid.generate(8)
  oPacket = { sCmd="fput", sReqId=sJobId, sSrc=sSrc, sDest=sDest, sContent=sContent}
  Send(Id,oPacket)
 
  bWait = true
  getResp = function ()
    while bWait do
      e,id,p,d = os.pullEvent("rednet_message")
      if p:sub(1,3) == "rc:" then
        oResp = textutils.unserialize(p:sub(4))
        if oResp.sReqId == sJobId then
            bWait = false
        end
      end
    end
  end
  parallel.waitForAny(timeout,getResp)
 
  if bWait == false then return oResp.sCmd == "sok"
  else return false end
end
 
function FGet(Id,sSrc,sDest)
  if Id == nil or sSrc == nil then
    return false
  end
  if sDest == nil then
    sDest = sSrc
  end
  if fs.exists(sDest) then
    return false
  end
 
  sJobId = guid.generate(8)
  oPacket = { sCmd="fget", sReqId=sJobId, sSrc=sSrc, sDest=sDest}
  Send(Id,oPacket)
 
  bWait = true
  getResp = function ()
    while bWait do
      e,id,p,d = os.pullEvent("rednet_message")
      if p:sub(1,3) == "rc:" then
        oResp = textutils.unserialize(p:sub(4))
        if oResp.sReqId == sJobId then
          bWait = false
        end
      end
    end
  end
  parallel.waitForAny(timeout,getResp)
 
  if bWait == false then
    if oResp.sCmd == "sok" then
      fG = fs.open(sDest,"w")
      fG.write(oResp.sContent)
      fG.close()
      return true
    end
  end
  return false
end
 
function timeout()
  os.sleep(1)
end