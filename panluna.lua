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

block_definitions = {
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

LineItems = {}

local inline_definitions = {
  Emph = {{content = Inlines}},
  Span = {{attributes = Attributes}, {content = Inlines}},
  Strong = {{content = Inlines}},
  Subscript = {{content = Inlines}},
  Superscript = {{content = Inlines}},
  Strikeout = {{content = Inlines}},
  SmallCaps = {{content = Inlines}},
  Note = {{content = Blocks}},
  Quoted = {{quote_type = QuoteType}, {content = Inlines}},
  Cite = {{content = Text}},
  Str = {{content = Text}},
  Code = {{attributes = Attributes}, {content = Text}},
  Math = {{format = MathType}, {content = Text}},
  RawInline = {{format = Text}, {content = Text}},
}

local Text = {}
local function Text.from_json(t)
  assert(type(t) == "string")
  return t
end

local Inline = {}
local function Inline.from_json_table(t)
  eltype = inline_definitions[t]
  el = {}
  for i, attr in eltype do
    attr_name, attr_type = attr
    el[attr_name] = attr_type:from_json_table(t.c[i])
  end
end

local Inlines = {}
local function Inlines.from_json_table(t)
  local res = {}
  for _, e in ipairs(t) do
    table.insert(res, Inline.from_json_table(e))
  end
  return res
end

local Str = {}
setmetatable(Str, Inline)
local function Str.from_json_table(s)
  -- FIXME: check type
  return s
end

function panluna.from_json(s)
  doc = json.decode(s)
  if doc.meta and doc.body and doc['pandoc-api-version'] then
    doc.body = panluna.from_json(doc.body)
    return doc
  end
  doc = json.decode(s)
  
end

