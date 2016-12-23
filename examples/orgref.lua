-- Use org-ref to output citations
--
-- Invoke with:
--    pandoc -t orgref.lua [READER-OPTIONS] | pandoc -f json [WRITER-OPTIONS]

panlunatic = require("panlunatic")

function Cite(s, cs)
  res = {}
  for _, cit in ipairs(cs) do
    if cit.citationMode == "AuthorInText" then
      cite_type = "cite"
    elseif cit.citationMode == "NormalCitation" then
      cite_type = "citep"
    else -- cit.citationMode == "SuppressAuthor"
      cite_type = "citeyear"
    end
    if cit.citationSuffix ~= "" or cit.citationPrefix ~= "" then
      table.insert(res, '[[' .. cite_type .. ':' .. cit.citationId .. ']' ..
                     '[' .. cit.citationPrefix ..
                     '::' .. cit.citationSuffix .. ']]')
    else
      table.insert(res, cite_type .. ':' .. cit.citationId)
    end
  end
  return panlunatic.Cite(panlunatic.RawInline("org", table.concat(res)), cs)
end

setmetatable(_G, {__index = panlunatic})
