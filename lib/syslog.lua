-- == SYSLOG ==
-- Copyright (c) 2018 by Rene K. Mueller <spiritdude@gmail.com>
-- License: MIT License (see LICENSE file)
-- Description:
--    syslog.print(what,"message")
--       what = syslog.INFO
--              syslog.WARN
--              syslog.ERROR
--              syslog.FATAL
-- History:
-- 2018/01/07: 0.0.1: first version
-- 2018/12/13: 0.0.2: log to file -- by leonstill@163.com

syslog = {
   INFO = 0,
   WARN = 1,
   ERROR = 2,
   FATAL = 3,
   info = 0,
   warn = 1,
   error = 2,
   fatal = 3,

   level = 0,
   --count = 0,
   
   verbose = function(lv)
      level = lv
   end,

   print = function(logtype, m, cb)
      local tm = { [0]='INFO', [1]='WARN', [2]='ERROR', [3]='FATAL' }
      local t
      --if arch=='esp8266' then
         t = tmr and (tmr.time() .. "." .. string.format("%03d",int((tmr.now()/1000)%1000))) or 0
      --else
      --   t = syslog.count
      --   syslog.count = syslog.count + 1
      --end
      if type(cb)=='function' then
         pcall(cb, logtype, m)
      else
         console.print((tm[logtype] or 'UNKNOWN') .. " [" .. t .. "] " .. m)
      end
   end,

   log = function(logtype, m) 
      local logfile = "demo/syslog.log";
      syslog.print(logtype, m, function()
         local fm = (tm[logtype] or 'UNKNOWN') .. " [" .. t .. "] " .. m
         console.print(fm)
         if file.open(logfile, "a+") then
            file.write(fm .. "\r\n")
            file.close()
         end
      end)
   end
}
