-- Make image paths relative by removing any leading slash.
--
-- Invoke with:
--    pandoc -t relimg.lua [READER-OPTIONS] | pandoc -f json [WRITER-OPTIONS]

panlunatic = require("panlunatic")
setmetatable(_G, {__index = panlunatic})

function Image(s, src, tit, attr)
  return panlunatic.Image(s, src:gsub("^/", ""), tit, attr)
end

