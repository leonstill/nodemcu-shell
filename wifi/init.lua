-- == WIFI ==
-- Copyright (c) 2018 by Rene K. Mueller <spiritdude@gmail.com>
-- License: MIT License (see LICENSE file)
-- Description: configure wifi
--
-- History:
-- 2018/01/17: 0.0.4: allow multiple stations and walk through them if one fails to connect
-- 2018/01/07: 0.0.3: renamed it to init.lua and conditional wifi/wifi.conf checking
-- 2018/01/03: 0.0.1: first version

if file.exists("wifi/wifi.conf") then
   local conf = dofile("wifi/wifi.conf")
   
   wifi.setmode(conf.mode == 'ap' and wifi.SOFTAP or conf.mode == 'station' and wifi.STATION or wifi.STATIONAP, true)
   
   if(conf.mode=='ap' or conf.mode=='stationap') then 
      wifi.ap.config(conf.ap.config)
      wifi.ap.setip(conf.ap.net)
      syslog.print(syslog.INFO,"wifi "..conf.ap.config.ssid.." access point ("..wifi.sta.getmac()..") started")
      if(conf.mode ~= 'stationap') then     -- if 'stationap' then let 'station' below call net.up.lua once
         -- -- DHCP is started only in SOFTAP mode !
         -- wifi.ap.dhcp.config(conf.ap.dhcp)
         -- if wifi.ap.dhcp.start() then
         --    syslog.print(syslog.INFO,"DHCP started")
         -- else
         --    syslog.print(syslog.INFO,"DHCP start failed")
         -- end
         -- start net app
        dofile("net.up.lua")
      end
   end
   if(conf.mode=='station' or conf.mode=='stationap') then
      --wifi.setphymode(conf.signal_mode)
      local sta_fails = 0
      local sta_id = 0
      if(type(conf.station.config)=='table' and conf.station.config.ssid) then
         syslog.print(syslog.INFO,"wifi: connecting to "..conf.station.config.ssid.." ...")
         wifi.sta.config(conf.station.config)
      else 
         -- multiple stations defined
         sta_id = sta_id + 1
         wifi.sta.config(conf.station[sta_id].config)
         syslog.print(syslog.INFO,"wifi: connecting to "..conf.station[sta_id].config.ssid.." ...")
      end
      wifi.sta.connect()
      wifi.sta.sethostname("ESP-"..node.chipid())
      if conf.station.net then
         wifi.sta.setip(conf.station.net)
      end
      wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,function(args)
         syslog.print(syslog.INFO,"wifi: connected to "..(sta_id > 0 and conf.station[sta_id].config.ssid or conf.station.config.ssid).." "..wifi.sta.getip())
         dofile("net.up.lua")
         wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED,function(args)
            syslog.print(syslog.WARN,"wifi: lost connectivity, reconnecting ...")
            dofile("net.down.lua")
         end)
      end)
      tmr.alarm(1,5000,1,function() 
         local s = wifi.sta.status()
         local ap = sta_id > 0 and conf.station[sta_id].config.ssid or conf.station.config.ssid
         if(s ~= wifi.STA_GOTIP) then
            syslog.print(syslog.INFO,"wifi: " .. (
               s == wifi.STA_IDLE and "idle ..." or
               s == wifi.STA_CONNECTING and "connecting ..." or
               s == wifi.STA_WRONGPWD and "wrong password" or
               s == wifi.STA_APNOTFOUND and "ap "..ap.." not found" or
               s == wifi.STA_FAIL and "fail" or
               s == wifi.STA_GOTIP and "got ip" or "" )
            )
            if(s==wifi.STA_APNOTFOUND and sta_id > 0) then -- try other station
               sta_fails = sta_fails + 1
               sta_id = sta_id + 1
               if sta_id <= #conf.station then
                  syslog.print(syslog.INFO,"wifi: connecting to "..conf.station[sta_id].config.ssid.." ...")
                  wifi.sta.config(conf.station[sta_id].config)
                  s = nil        -- reset error
               end
            end
         end
         if((s==wifi.STA_WRONGPWD) or (s==wifi.STA_APNOTFOUND) or (s==wifi.STA_FAIL) or (s==wifi.STA_GOTIP)) then
            tmr.unregister(1)
         end
      end)
   else
      -- 如果有cache则清除cached，并重启
      if wifi.sta.getapinfo() then
         wifi.sta.disconnect(function()
            syslog.print(syslog.INFO, 'dddddddddddddddd')
         end)
         wifi.sta.clearconfig()
         --node.restart()
      end
   end
else
   syslog.print(syslog.info,"no wifi/wifi.conf")
end
