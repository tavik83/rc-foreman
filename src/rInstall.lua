fs.makeDir("/apis")
fs.makeDir("/etc")
 
fs.delete("/apis/RC")
shell.run("pastebin get f2dXMGfh /apis/RC")
fs.delete("/rBoot")
shell.run("pastebin get 5dJYJLRJ /rBoot")
fs.delete("/apis/nav")
shell.run("pastebin get yPAQWwEs /apis/Nav")
fs.delete("/apis/guid")
shell.run("pastebin get hu3hwWzJ /apis/guid")
fs.delete("/startup")
shell.run("pastebin get ihRLskKg /startup")
shell.run("reboot")