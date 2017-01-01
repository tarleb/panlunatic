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
local _version = "0.0.1"

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
function Text:new(s)
  local t = {type = "Text", value = s}
  setmetatable(t, self)
  self.__index = self
  return t
end
function Text:from_json(s)
  assert(type(s) == "string", "String expected as value of type 'Text'")
  return self:new(s)
end
function Text:to_json_structure()
  return self.value
end
function Text.__tostring(text)
  return text.value
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

local List = function(item_type)
  local list_type = Type:new("List(" .. item_type.type .. ")")
  list_type.item_type = item_type
  list_type.is_list = true
  function list_type:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
  end
  function list_type:from_json(t)
    local res = {}
    for _, item in ipairs(t) do
      table.insert(res, item_type:from_json(item))
    end
    return res
  end
  function list_type:to_json_structure()
    local res = {}
    for i, v in ipairs(self) do
      res[#res + 1] = v:to_json_structure()
    end
    return res
  end
  return list_type
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

function Element:from_json(t)
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

  local element_type, content = t.t, t.c
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

local Inline = Element:new({type = "Inline"})
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
  Emph = {content = List(Inline)},
  Image = {{attributes = Attributes}, {content = List(Inline)},
    {{src = Text}, {title = Text}}},
  Link = {{attributes = Attributes}, {content = List(Inline)},
    {{src = Text}, {title = Text}}},
  LineBreak = {},
  Math = {{format = MathType}, {content = Text}},
  Note = {content = Blocks},
  Quoted = {{quote_type = QuoteType}, {content = List(Inline)}},
  RawInline = {{format = Text}, {content = Text}},
  SmallCaps = {content = List(Inline)},
  SoftBreak = {},
  Space = {},
  Span = {{attributes = Attributes}, {content = List(Inline)}},
  Str = {content = Text},
  Strikeout = {content = List(Inline)},
  Strong = {content = List(Inline)},
  Subscript = {content = List(Inline)},
  Superscript = {content = List(Inline)}
}

function Inline:get_definition()
  return Inline.definitions[self.type]
end

function Inline.get_definitions()
  return Inline.definitions
end

function Inline:to_json_structure()
  local eldef = self:get_definition()
  local json_struct = {t = self.type}
  if #eldef == 0 then
    json_struct.c = self.content:to_json_structure()
  else
    local attr_list = {}
    for i, _ in ipairs(eldef) do
      table.insert(attr_list, self[i]:to_json_structure())
    end
    json_struct.c = attr_list
  end
  return json_struct
end

local M = {
  MathType = MathType,
  Text = Text,
  Inline = Inline,
  flattened = flattened
}

-- export type constructors for elements
for eltype, definition in pairs(Inline.definitions) do
  M[eltype] = function (...)
    local element_args = {type = eltype}
    if next(definition) == nil then
      error("Empty definition")
    elseif #definition == 0 then
      local _, attr_type = next(definition)
      if #attr_type > 0 or attr_type.is_list then
        element_args.content = attr_type:new{...}
      else
        element_args.content = attr_type:new(...)
      end
    else
      for i, v in ipairs(...) do
        attr_name, _ = next(definition[i])
        element_args[attr_name] = v
      end
    end
    return Inline:new(element_args)
  end
end

return M
