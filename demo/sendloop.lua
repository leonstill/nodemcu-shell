-- sendloop.lua
-- 通过mqtt方式发送登录及状态信息到服务器
--   by leonstill@163.com  2018-12-13
local conf = ... or { host = "114.215.120.146", port = 1883, interval = 1000}
local json = sjson

if (wifi.getmode() ~= wifi.STATION and wifi.getmode() ~= wifi.STATIONAP) then
    syslog.print(syslog.WARN, "wifi mode should be 'wifi.STATION' or 'wifi.STATIONAP', but now is "..wifi.getmode().."!")
    return
end

m_dis={}
function dispatch(m,t,pl)
    print(t .. ":" .. (pl or "nil"))
	if pl~=nil and m_dis[t] then
		m_dis[t](m,pl)
	end
end

function topic1func(m,pl)
	print("get1: "..pl)
end

m_dis["/topic1"]=topic1func

-- check mqtt is exist or not
if not mqtt then 
    syslog.print(syslog.FATAL, "MQTT module is not installed!")
    return
end

-- init mqtt client with logins, keepalive timer 120sec
local id = "esp8266_" .. node.chipid()
local m = mqtt.Client(id, 60, "liang", "peng")

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(client) 
    print("connected , heap size:"..node.heap()) 
end)
m:on("offline", function(client) print ("offline") end)

-- on publish message receive event
m:on("message", dispatch)

-- for TLS: m:connect("192.168.11.118", secure-port, 1)
m:connect(conf.host, conf.port, 0, function(client)
        print("client connected")
        local data = { time=rtctime.get() }
        client:publish("/wifi/login", json.encode(data), 1, 0, function(client) end)
        -- Calling subscribe/publish only makes sense once the connection
        -- was successfully established. You can do that either here in the
        -- 'connect' callback or you need to otherwise make sure the
        -- connection was established (e.g. tracking connection status or in
        -- m:on("connect", function)).

        -- subscribe topic with qos = 0
        --client:subscribe({["/topic"]=0, ["/blink"]=0}, function(client) print("subscribe success") end)
        -- publish a message with data = hello, QoS = 0, retain = 0

        local mytimer = tmr.create()
        mytimer:register(10, tmr.ALARM_SEMI, function()
            mytimer:stop()
            wifi.sta.getap(1, function (t) -- (SSID : Authmode, RSSI, BSSID, Channel)
                local index = 1
                --print("nt: " .. sjson.encode(nt))
                client:publish("/wifi/status", json.encode(t), 1, 0)
                print('.')
                mytimer:start()
            end)
        end)
        mytimer:start()

    end, 
    function(client, reason)
        print("connection failed reason: " .. reason)
    end)

--m:close();
-- you can call m:connect again

