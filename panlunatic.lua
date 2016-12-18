-- This is a custom JSON writer for pandoc. It is inteded to be used instead of
-- a filter, if no other filtering package is available.
--
-- Invoke with: pandoc -t panlunatic.lua

panluna = require("panluna")

-- Modify output at will, e.g. turn emphasis into strong:
--
-- function Emph(s)
--   return panluna.Strong(s)
-- end
--
-- or remove all divs
--
-- function Div(s, attr)
--   return s
-- end

setmetatable(_G, {__index = panluna})
