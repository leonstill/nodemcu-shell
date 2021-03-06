-- == Display CLI ==
-- Copyright (c) 2018 by Rene K. Mueller <spiritdude@gmail.com>
-- License: MIT License (see LICENSE file)
-- Description:
--    Misc. commands dealing with display via CLI, see `man display`
-- History:
-- 2018/01/18: 0.0.1: first version

return function(...)
   table.remove(arg,1)

   local function man(c) dofile("shell/man.lua")('man',c) end

   if display and display.disp then
      local cmd = table.remove(arg,1)
      if not display.print then
         dofile("lib/display.lua")
      end
      if cmd == 'contrast' then
         if arg[1] then
            display.disp:setContrast(arg[1] and tonumber(arg[1]) or 255)
         else
            man('display')
         end
      elseif cmd == 'font' then
         if arg[1] then
            local lib = u8g2 and "u8g2" or "u8g"
            local f,err = loadstring("display.setFont("..lib.."."..arg[1]..")")
            if f then
               f()
            else
               console.print("font <"..arg[1].."> not available: "..err)
            end
         else
            man('display')
         end
      elseif cmd == 'rotate' then
         if arg[1] then
            display.setRotation(tonumber(arg[1]))
         else
            man('display')
         end
      elseif cmd == 'print' then
         for i,v in ipairs(arg) do
            display.print(v)
         end
      elseif cmd == 'clear' then
         display.clear()
      elseif cmd == 'flush' then
         display.flush()
      elseif cmd == 'on' then
         display.disp:sleepOff()
      elseif cmd == 'off' then
         display.disp:sleepOn()
      elseif cmd == 'info' or cmd == nil then
         console.print(string.format("size: %dx%d",display.width,display.height))
      else 
         man('display')
      end
   else
      console.print("no display defined")
   end
end
