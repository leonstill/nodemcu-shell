-- fileloop.lua
-- 刷新wifi状态并保存到指定文件中
local conf = ... or {}

if (wifi.getmode() ~= wifi.STATION and wifi.getmode() ~= wifi.STATIONAP) then
    syslog.print(syslog.WARN, "wifi mode should be 'wifi.STATION' or 'wifi.STATIONAP', but now is "..wifi.getmode().."!")
    return
end

if (wifi and wifi.sta and http) then
    local mytimer = tmr.create()
    local interval = conf.interval or 3000
    conf.file = conf.file or "www/wifiscan.json"
    mytimer:register(interval, tmr.ALARM_AUTO, function()
        wifi.sta.getap(1, function (t) -- (SSID : Authmode, RSSI, BSSID, Channel)
            --print("http url: " .. conf.url)
            -- local nt = {}
            -- local index = 1
            -- for ssid,v in pairs(t) do
            --     --local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
            --     --print(string.format("%32s",ssid).."\t"..bssid.."\t  "..rssi.."\t\t"..authmode.."\t\t\t"..channel)
            --     nt[index] = { ssid = ssid, data = v }
            --     index = index + 1
            -- end
            --print("nt: " .. sjson.encode(t))
            if file.open(conf.file, "w+") then
                file.write(sjson.encode(t))
                file.close()
            else
                syslog.print(syslog.ERROR, "open file '" .. conf.file .. "' failed!")
            end
        end)
    end)
    mytimer:start()
end
