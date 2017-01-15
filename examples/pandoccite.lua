-- Convert citations to pandoc-markdown syntax
--
-- Invoke with:
--    pandoc -t pandoccite.lua [READER-OPTIONS] | pandoc -f json [WRITER-OPTIONS]

panlunatic = require("panlunatic")
setmetatable(_G, {__index = panlunatic})

function Cite(s, cs)
  local res = {}
  local in_text = false
  for _, cit in ipairs(cs) do
    local citeSym
    local spc
    if cit.citationPrefix == "" then
      spc = ""
    else
      spc = Space()
    end
    if cit.citationMode == "AuthorInText" then
      in_text = true
      citeSym = "@"
    elseif cit.citationMode == "NormalCitation" then
      citeSym = "@"
    elseif cit.citationMode == "SuppressAuthor" then
      citeSym = "-@"
    else
      error("Unknown citation mode: " .. cit.citationMode)
    end
    res[#res + 1] = cit.citationPrefix .. spc ..
      Str(citeSym .. cit.citationId) .. cit.citationSuffix
  end
  if in_text then
    return panlunatic.Cite(table.concat(res, ", "), cs)
  else
    return panlunatic.Cite(Str "[" .. table.concat(res, Str ";") .. Str "]", cs)
  end
end

