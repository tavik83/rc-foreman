--[[
  Client bootstrap process:
 
  1: check for shell definition
      /etc/shell will contain 1 line with the absolute path to the desired boot app
      if none is specificed the default interactive shell will be used
  2: check for existance of desired bootup app, if it doesn't exist check for the
      .bk (backup) copy.  Exit to shell if backup is also missing
]]
shell.run("clear")
print ("rBoot::RC | network enabled shell")

if guid == nil then
  os.loadAPI("/apis/guid")
end
if RC == nil then
  os.loadAPI("/apis/RC")
  RC.Init(shell)
end

if fs.exists("/etc/shell") then
  local f = fs.open("/etc/shell")
  sh = f.readLine()
  f.close()
else
  sh = "shell"
end
 
if (sh ~= "shell" and fs.exists(sh) == false) then
  if fs.exists(sh..".bk") == false then
    print("RedNet Bootstrap failed!")
    shell.exit()
  else
    fs.copy(sh..".bk",sh)
  end
else
  if sh ~= "shell" then
    fs.delete(sh..".bk")
    fs.copy(sh,sh..".bk")
  end
  local s = function()
    shell.run(sh)
  end

  parallel.waitForAny(RC.Listen, s)
 
  --[[
    Following execution, check for updates:
      .upd : 1 line file containing the pastebin ID of the script to replace the app
      .sxs : replacement script download
  ]]  
  if sh ~= "shell" then
    if fs.exists(sh..".upd") then
      if fs.exists(sh..".sxs") then
        fs.delete(sh..".sxs")
      end
     
      local u = fs.open(sh..".upd","r")
      local sxs = u.readLine()
      u.close()
      shell.run("pastebin get "..sxs.." "..sh".sxs")
      if fs.exists(sh..".sxs") then    
        fs.delete(sh)
        fs.move(sh..".sxs",sh)
        fs.delete(sh..".sxs")
      end
    end
  end
  shell.run("reboot")
end