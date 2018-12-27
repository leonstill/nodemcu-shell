-- postloop.lua
-- 刷新wifi状态并post到服务器
local conf = ... or { url = "http://114.215.120.146:10088/wifi/update" }

if (wifi.getmode() ~= wifi.STATION and wifi.getmode() ~= wifi.STATIONAP) then
    syslog.print(syslog.WARN, "wifi mode should be 'wifi.STATION' or 'wifi.STATIONAP', but now is "..wifi.getmode().."!")
    return
end

if (wifi and wifi.sta and http) then
    local mytimer = tmr.create()
    --local interval = conf.interval
    mytimer:register(10, tmr.ALARM_SEMI, function()
        mytimer:stop()
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
            -- print("nt: " .. sjson.encode(t))
            if file.open("www/data.json", "w+") then
                file.write(sjson.encode(t))
                file.close()
            end
            http.post(conf.url, 'Content-Type: application/json\r\n', sjson.encode(t), function(code, data)
                print(">>>")
                if (code < 0) then
                    print("HTTP request failed")
                else
                    -- print(code, data)
                end
                mytimer:start()
            end)
        end)
    end)
    mytimer:start()
end
