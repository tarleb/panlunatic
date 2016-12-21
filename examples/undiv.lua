-- Example script to unwrap div content.
--
-- Invoke with:
--    pandoc -t undiv.lua [READER-OPTIONS] | pandoc -f json [WRITER-OPTIONS]

panluna = require("panluna")

function Div(s, attr)
  return s
end

setmetatable(_G, {__index = panluna})
