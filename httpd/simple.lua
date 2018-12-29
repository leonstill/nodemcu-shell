-- == Simple HTTP Server ==
-- Copyright (c) 2018 by Rene K. Mueller <spiritdude@gmail.com>
-- License: MIT License (see LICENSE file)
-- Description:
--    Very basic web-server serving just static files for now
-- Todo:
--    - Reduce memory leak
--    - support .lua files (to execute)
--
-- History:
-- 2018/12/30: 0.0.5: fixed the memory leak! optimize some error processing .
-- 2018/12/15: 0.0.4: add 'text/css' surpport  -- leonstill@163.com
-- 2018/02/05: 0.0.3: esp32 support
-- 2018/01/06: 0.0.2: adding collectgarbage() and nil local variables, reduces leaks but still not entirely gone
-- 2018/01/05: 0.0.1: first version, very simple

-- 注意： 每次ajax请求会丢失240或232个字节，很快程序会崩溃，未找到原因。

if httpd_srv then          -- httpd_srv exists already, ignore call (e.g. from net.up.lua)
   return
end

local mm = { ["html"]="text/html", ["txt"]="text/plain", ["png"]="image/x-png", ["jpg"]="image/jpeg", ["ico"]="image/x-icon", ["css"]="text/css" }

local conf = dofile("httpd/httpd.conf")
if arc=='esp8266' then
   local ip = wifi.ap.getip() or wifi.sta.getip()
   syslog.print(syslog.INFO,"httpd:simple started on "..ip.." port "..conf.port)
else 
   syslog.print(syslog.INFO,"httpd:simple started on port "..conf.port)
end

httpd_srv = net.createServer(net.TCP,10)


local function onConnection(conn)
   --syslog.print(syslog.INFO,"client IP:"..clientIp)

   local function close(c) 
      c:on('sent', nil) -- release closures context
      c:on('receive', nil)
      c:close()
      if conn then
         conn:on("receive", nil)
         conn:on("disconnection", nil)
--         conn:close()
      end
      collectgarbage() 
   end

   -- gv为url中请求参数，即‘？’后的所有值解析成的table，如果没有则为空表。
   local function sendFile(client,fn,req,gv) 
      local h = "HTTP/1.0 200 OK\r\n"
      local fno = fn
      
      fn = conf.root .. fn

      local m = "text/html"
      local ext = string.match(fn,"\.(%w+)$")
      if mm[ext] then
         m = mm[ext]
      end

      if string.match(fn,"/$") then
         fn = fn .. "index.html"
      end
      if file.exists(fn..".gz") then
         fn = fn .. ".gz"
         h = h .. "Content-Encoding: gzip\r\n"
         h = h .. "Cache-Control: public, max-age=86400\r\n"
         -- h = h .. "X-Info: something\r\n"
      end 
      
      if file.exists(fn) then
         if string.match(fn,"\.lua$") then         -- a script?
            if conf.debug > 0 then
               console.print("httpd: execute",fn)
            end
            client:on('sent', function(c) 
               close(c)
               if conf.debug > 0 then
                  console.print("after sent>>",node.heap())
               end
            end)
            dofile(fn)(client,req,gv)                   -- let's execute it

         else 
            h = h .. "Content-Type: " .. m .. "\r\n"

            local st
            if arch=='esp8266' then
               st = file.stat(fn)
               h = h .. "Content-Length: " .. st['size'] .. "\r\n"
            end
            h = h .. "Connection: close\r\n"
            
            if(conf.debug > 0) then
               console.print("httpd: send",fno,fn,m,st and st['size'] or 0)
            end
      
            h = h .. "\r\n"   -- end of header
            
            local fd = file.open(fn,'r')
            local buf = nil
            local function doSend(c)   -- send it chunk wise, it's slower, but safer
               buf = fd:read(512)
               if buf then
                  client:send(buf)
               else
                  fd:close()
                  close(client)
               end
               collectgarbage()
            end
      
            client:on('sent',doSend)     -- the cumbersome part
            client:send(h)               -- send the header
            --doSend()                -- then the rest chunk-wise
         end
      else 
         client:send("HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\n404 NOT FOUND", function(c) close(client) end)
      end
      collectgarbage()
   end

   local function onReceive(client,request)
      --console.print("request="..request)

      local method, path = string.match(request,"^([A-Z]+) (.+) HTTP");
      --console.print("method="..method,"path="..path)
      local gv = {}
      if true then
         local vars = string.match(path,"%?(.*)$")
         if vars then
            path = string.gsub(path,"%?.*$","")
            string.gsub(vars,"([%w_]+)=([^&]*)&*",function(k,v)
              -- todo: decode k,v
              --console.print("\t"..k.."="..v)
              gv[k] = v
            end)
         end
         -- we later process gv { }
      end
      if(conf.debug > 1) then
         console.print("before send",node.heap())
      end
      
      if(conf.debug > 2) then
         client:on("sent",function(c) close(client) end)
         client:send("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\ntest")
      else
         sendFile(client,path,request,gv)        -- sending file isn't that trivial, all is async
         -- when we reach here, we do not know if it's sent already
      end
      
      if(conf.debug > 1) then
         console.print("after send",node.heap())
      end
   end
   
   conn:on("receive", onReceive)
   conn:on("disconnection",function(c)
      if conf.debug > 0 then
         console.print("httpd: closed connection", node.heap())
      end
      close(c)
   end)
end

httpd_srv:listen(conf.port, onConnection)
