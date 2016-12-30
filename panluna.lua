--[[
panluna.lua

Copyright (c) 2016 Albert Krewinkel

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.

]]
local panluna = {_version = "0.0.1"}

local json = require("dkjson")

local block_definitions = {
  Plain = {content = Inlines},
  Para = {content = Inlines},
  BlockQuote = {content = Blocks},
  Div = {attributes = Attributes, content = Blocks},
  Header = {level = HeaderLevel, attributes = Attributes, content = Blocks },
  CodeBlock = {attributes = Attributes, content = Text},
  RawBlock = {format = Text, content = Text},
  BulletList = {content = ListItems},
  OrderedList = {start = Start, style = Style, delimiter = ListDelimiter, content = ListItems},
  DefinitionList = {},
  LineBlock = {content = LineItems}
}

local LineItems = {}
local Citations = {}

local Text = {}
function Text.from_json(t)
  assert(type(t) == "string", "String expected as value of type 'Text'")
  return t
end

local MathType = {}
function MathType.from_json(t)
  return t.t
end

local get_inline_definition

local Inline = {}
function Inline.from_json(t)
  local element_definition = get_inline_definition(t.t)
  local el = {type = t.t}
  if (#element_definition == 0 and next(element_definition) ~= nil) then
    local attr_name, attr_type = next(element_definition)
    el[attr_name] = attr_type.from_json(t.c)
  else
    for i, attr in ipairs(element_definition) do
      local attr_name, attr_type = next(attr)
      el[attr_name] = attr_type.from_json(t.c[i])
    end
  end
  return el
end

local Inlines = {}
function Inlines.from_json(list_of_inlines)
  local res = {}
  for _, element in ipairs(list_of_inlines) do
    table.insert(res, Inline.from_json(element))
  end
  return res
end

-- local Str = {}
-- setmetatable(Str, Inline)
-- function Str.from_json(s)
--   -- FIXME: check type
--   return s
-- end

-- Order matters, so we need arrays of type definitions.
local inline_definitions = {
  Cite = {{citations = Citations}, {content = Text}},
  Code = {{attributes = Attributes}, {content = Text}},
  Emph = {content = Inlines},
  Image = {{attributes = Attributes}, {content = Inlines},
          {{src = Text}, {title = Text}}},
  Link = {{attributes = Attributes}, {content = Inlines},
    {{src = Text}, {title = Text}}},
  LineBreak = {},
  Math = {{format = MathType}, {content = Text}},
  Note = {content = Blocks},
  Quoted = {{quote_type = QuoteType}, {content = Inlines}},
  RawInline = {{format = Text}, {content = Text}},
  SmallCaps = {content = Inlines},
  SoftBreak = {},
  Space = {},
  Span = {{attributes = Attributes}, {content = Inlines}},
  Str = {content = Text},
  Strikeout = {content = Inlines},
  Strong = {content = Inlines},
  Subscript = {content = Inlines},
  Superscript = {content = Inlines}
}

get_inline_definition = function (inline_type)
  return inline_definitions[inline_type]
end


function panluna.from_json(s)
  doc = json.decode(s)
  if doc.meta and doc.body and doc['pandoc-api-version'] then
    doc.body = panluna.from_json(doc.body)
    return doc
  end
  doc = json.decode(s)
end

panluna.Text = Text
panluna.Str = Str
panluna.Inline = Inline
panluna.Inlines = Inlines
panluna.inline_definitions = inline_definitions
return panluna
