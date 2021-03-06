-- == Args ==
-- Copyright (c) 2018 by Rene K. Mueller <spiritdude@gmail.com>
-- License: MIT License (see LICENSE file)
-- Description: just displays the command-line arguments
--
-- History:
-- 2018/01/03: 0.0.1: first version

return function(...)
   for k,v in ipairs(arg) do
      console.print("arg[" .. k .. "] = '" .. v .. "'")
   end
end
