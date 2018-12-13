-- demo
-- 刷新wifi状态并提交到aliyun上
if not file.exists("demo/demo.conf") then
    syslog.print(syslog.ERROR, "no demo/demo.conf")
    return
end

local conf = dofile("demo/demo.conf")
print(conf.looptype or "postloop")

local loopfile = "demo/" .. (conf.looptype or "postloop") .. ".lua"
if file.exists(loopfile) then
    syslog.print(syslog.INFO, "load '" .. loopfile .. "' ...")
    assert(loadfile(loopfile))(conf)
    --dofile(loopfile)(conf)  这样不行
else
    syslog.print(syslog.ERROR, "file '" .. loopfile .. "' isn't exists!")
end
