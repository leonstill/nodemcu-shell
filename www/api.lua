-- == Sample RESTful API with httpd/simple.lua ==
-- Copyright (c) 2018 by Rene K. Mueller <spiritdude@gmail.com>
-- License: MIT License (see LICENSE file)
-- Description: gives a a basic framework to a RESTendpoint
--    api.lua?req=<r>
--    r:
--       chipid
--       heap
--       filelist
--       upload
--
-- History:
-- 2018/01/13: 0.0.2: req=chipid and req=chipid,heap,filelist combined as well
-- 2018/01/06: 0.0.1: first version

return function(conn,req,gv)
   dofile("httpd/header.lua")(conn,200,"application/json")
   syslog.print(syslog.INFO, sjson.encode(gv))
   local d = { }
   local w = gv.req
   if w then
      string.gsub(w,"([^,]+),*",function(k)
         --console.print("=="..k)
         if k == 'chipid' then
            d.chipid = node.chipid()
         elseif k == 'heap' then
            d.heap = node.heap()
         elseif k == 'filelist' then
            d.filelist = file.list()
         elseif k == 'ip' then
            d.ip = wifi.sta.getip()
         elseif k == 'ap' then
            d.ap = wifi.ap.getconfig(true)
         elseif k == 'apinfo' then
            d.apinfo = wifi.sta.getapinfo()
         elseif k == 'wifiscan' then
            if file.open('www/wifiscan.json') then
               d.wifiscan = sjson.decode(file.read('\n'))
               file.close()
            end
         elseif k == 'upload' then
            -- future, uploading a file
         else
            d.error = "UNKNOWN REQUEST: "..k
         end
      end)
      conn:send(sjson.encode(d))
   elseif gv.switch then
      gpio.mode(1, gpio.OUTPUT)
      if gv.switch == 'on' then
         gpio.write(1, gpio.LOW)
      else
         gpio.write(1, gpio.HIGH)
      end
      d.success = 1
      conn:send(sjson.encode(d))
   else
      d.error = "UNKNOWN REQUEST"
      conn:send(sjson.encode(d))
   end
   gv = nil
   collectgarbage()
end
