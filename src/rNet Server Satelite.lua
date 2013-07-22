---- Rednet server satelite
-- Open Wireless Modem and
-- start listening for rednet messages
shell.run("clear")
rednet.open("top")
print("RedNet Management Server... ")
 
while true do
  local e,sid,q = os.pullEvent("rednet_message")
  print(sid.."> "..q)
         local qry = { }
         for i in string.gmatch(q, "%S+") do
                table.insert(qry, i)
         end
       
         if qry[1] == "ack" then
                 rednet.send(sid,"ack")
  elseif qry[1] == "update" then
    updhash = qry[2]
    if fs.exists("/disk/rUpdate") then
      fs.delete("/disk/rUpdate")
    end
    local upd = fs.open("/disk/rUpdate","w")
    print(updhash)
    upd.writeLine(updhash)
    upd.close()
    print("Updating Server Script - " .. qry[2])
    return
         elseif qry[1] == "lsc" then
   rednet.broadcast("lsc")
                 eto = os.startTimer(2)
                 local to = false
                 while to == false do
                        --event type, client/event id, client response, client distance
                        elsc,cid,cr,cd = os.pullEvent()
                        if cid == eto then
                                to = true
                        elseif elsc == "rednet_message" then
                                rednet.send(sid,cid..">"..cr)
                        end
                end
         elseif qry[1] == "send" then
   local target = tonumber(qry[2])       
          table.remove(qry,1)
          table.remove(qry,1)
          qry = table.concat(qry, " ")
         
          if target == 0 then
                  rednet.broadcast("r:" .. qry)
          else
            rednet.send(target,"r:" .. qry)
     print(target .. "> " .. qry)
   end
  end
end