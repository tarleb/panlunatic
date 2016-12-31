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

--
-- Helper functions
--

local function flattened(t)
  local res = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      for k1, v1 in pairs(flattened(v)) do
        res[k1] = v1
      end
    end
    res[k] = v
  end
  return res
end

local block_definitions = {
  Plain = {content = Inlines},
  Para = {content = Inlines},
  BlockQuote = {content = Blocks},
  Div = {attributes = Attributes, content = Blocks},
  Header = {level = HeaderLevel, attributes = Attributes, content = Blocks },
  CodeBlock = {attributes = Attributes, content = Text},
  RawBlock = {format = Text, content = Text},
  BulletList = {content = ListItems},
  OrderedList = {{start = ListStart, style = ListNumberStyle,
                  delimiter = ListNumberDelim}, content = ListItems},
  DefinitionList = {},
  LineBlock = {content = {Inlines}}
}

local LineItems = {}
local Citations = {}

local Text = {}
function Text:from_json(t)
  assert(type(t) == "string", "String expected as value of type 'Text'")
  return t
end

local Type = {}
function Type:new(type_name)
  local t = {type = type_name}
  setmetatable(t, self)
  return t
end
function Type:from_json(t)
  return self:new(t.t)
end
function Type.__tostring(t)
  return t.type
end

local MathType = Type:new("MathType")

local Attributes = Type:new("Attributes")
function Attributes:new(attr)
  setmetatable(attr, self)
  self.__index = self
  return attr
end
function Attributes:from_json(t)
  return self:new{identifier = t[1], classes = t[2], key_values = t[3]}
end


local Element = Type:new("Element")
function Element:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  return t
end

function Element:build(element_type, content)
  local function get_value(c, value_type)
    if #value_type > 0 then
      local _, list_element_type = next(value_type)
      local res = {}
      for _, element in ipairs(c) do
        table.insert(res, list_element_type:from_json(element))
      end
      return res
    else
      return value_type:from_json(c)
    end
  end

  local element = self:new{type = element_type}
  local definition = element:get_definition()
  if #definition == 0 and next(definition) ~= nil then
    local attr_name, attr_type = next(definition)
    element[attr_name] = get_value(content, attr_type)
  else
    for i, attr in ipairs(definition) do
      local attr_name, attr_type = next(attr)
      element[attr_name] = get_value(content[i], attr_type)
    end
  end
  return element
end

function Element:from_json(t)
  return self:build(t.t, t.c)
end


local Inline = Element:new()
function Inline:new(o)
  o.type = o.type or o.t
  assert(type(o.type) == "string", "No element type was specified")
  setmetatable(o, self)
  self.__index = self
  return o
end

function Inline:validate()
  for key,_ in pairs(flattened(self.get_definition(self.type))) do
    if type(key) == "string" and self[key] == nil then
      error("Required key '" .. key .. "' was not found.")
    end
  end
  return true
end

Inline.definitions = {
  Cite = {{citations = Citations}, {content = Text}},
  Code = {{attributes = Attributes}, {content = Text}},
  Emph = {content = {Inline}},
  Image = {{attributes = Attributes}, {content = {Inline}},
    {{src = Text}, {title = Text}}},
  Link = {{attributes = Attributes}, {content = {Inline}},
    {{src = Text}, {title = Text}}},
  LineBreak = {},
  Math = {{format = MathType}, {content = Text}},
  Note = {content = Blocks},
  Quoted = {{quote_type = QuoteType}, {content = {Inline}}},
  RawInline = {{format = Text}, {content = Text}},
  SmallCaps = {content = {Inline}},
  SoftBreak = {},
  Space = {},
  Span = {{attributes = Attributes}, {content = {Inline}}},
  Str = {content = Text},
  Strikeout = {content = {Inline}},
  Strong = {content = {Inline}},
  Subscript = {content = {Inline}},
  Superscript = {content = {Inline}}
}

function Inline:get_definition()
  return Inline.definitions[self.type]
end

function Inline.get_definitions()
  return Inline.definitions
end

function Inline.to_json(element)
  return build_json_structure(element, Inline)
end

function build_json_structure(element)
  local eldef = getmetatable(element).get_definition(element.type)
  local json_struct = {}
  return json_struct
end

function panluna.from_json(s)
  doc = json.decode(s)
  if doc.meta and doc.body and doc['pandoc-api-version'] then
    doc.body = panluna.from_json(doc.body)
    return doc
  end
  doc = json.decode(s)
end

panluna.MathType = MathType
panluna.Text = Text
panluna.Str = Str
panluna.Inline = Inline
panluna.Inlines = Inlines
panluna.flattened = flattened
return panluna
