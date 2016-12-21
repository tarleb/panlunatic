-- Turn emphasized into strong text.
--
-- Invoke with:
--    pandoc -t emph2strong.lua [READ-OPTIONS] | pandoc -f json [WRITE-OPTIONS]

panluna = require("panluna")

function Emph(s)
  return panluna.Strong(s)
end

setmetatable(_G, {__index = panluna})
