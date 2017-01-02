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

-- A Type of sorts
local Type = {}
function Type:new(type_name)
  local t = {type = type_name}
  setmetatable(t, self)
  self.__index = self
  return t
end
function Type:from_json(t)
  return self:new(t.t)
end
function Type.__tostring(t)
  return t.type
end

local Nullary = Type:new("Nullary")
function Nullary:new(name)
  local t = {}
  local mt = Type:new(name)
  mt.__tostring = function (t)
    return tostring(getmetatable(t))
  end
  setmetatable(t, mt)
  return t
end
function Nullary:from_json(t)
  return self
end

-- Nullary type constructor
local Nullary = function(nullary_type)
  local nullary = Type:new("Nullary(" .. nullary_type.type .. ")")
  nullary.__tostring = function (t)
    return tostring(getmetatable(t))
  end
  function nullary:new(name)
    local t = {}
    setmetatable(t, nullary)
    return t
  end
  function nullary:from_json(t)
    return self
  end
  return nullary
end

-- Text (normal strings)
local Text = Type:new("Text")
function Text:new(s)
  local t = {value = s}
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
  return '"' .. text.value:gsub('"', '\\"') .. '"'
end

-- List type
local ListConstructor = Type:new("ListConstructor")
ListConstructor.is_list = true
ListConstructor.__index = ListConstructor
function ListConstructor:__call(item_type)
  assert(item_type.type, "The item type must be a type.")
  local list_type = Type:new("List(" .. item_type.type .. ")")
  list_type.item_type = item_type
  setmetatable(list_type, ListConstructor)
  function list_type:new(t)
    print("HELLO!!!")
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
  end
  function list_type.__tostring(list)
    local buffer = {}
    for _, v in ipairs(list) do
      buffer[#buffer + 1] = tostring(v)
    end
    return '[' .. table.concat(buffer, ',') .. ']'
  end
  return list_type
end
function ListConstructor:from_json(t)
  local res = {}
  for _, item in ipairs(t) do
    table.insert(res, self.item_type:from_json(item))
  end
  return res
end
function ListConstructor:to_json_structure()
  local res = {}
  for i, v in ipairs(self) do
    res[#res + 1] = v:to_json_structure()
  end
  return res
end
function ListConstructor.__tostring(list)
  local buffer = {}
  for _, v in ipairs(list) do
    buffer[#buffer + 1] = tostring(v)
  end
  return '[' .. table.concat(buffer, ',') .. ']'
end

-- Create a new list type with the given item type
local List = ListConstructor:new("List")
-- local List = Type:new("List")
-- setmetatable(List, ListConstructor)
function List:new(t)
  print("HELLO!!!")
  t = t or {}
  local mt = {__index = function(list) return "TESTS" end}
  setmetatable(t, mt)
  self.__index = mt
  return t
end


-- Document elements
local Element = Type:new("Element")
function Element:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  return t
end
function Element:from_json(t)
  local element_type, content = t.t, t.c
  local element = self:new{type = element_type}
  local definition = element:get_definition()
  if #definition == 0 and next(definition) ~= nil then
    local attr_name, attr_type = next(definition)
    -- Don't set anything if there is no attribute name.
    if attr_name then
      element[attr_name] = attr_type:from_json(c)
    end
  else
    for i, attr in ipairs(definition) do
      local attr_name, attr_type = next(attr)
      element[attr_name] = attr_type:from_json(content[i])
    end
  end
  return element
end
function Element:from_json(t)
  local element_type, content = t.t, t.c
  local element = self:new{type = element_type}

  local function set_attr(definition, attr_content)
    local attr_name, attr_type = next(definition)
    element[attr_name] = attr_type:from_json(attr_content, attr_type)
  end

  local attribute_definitions = element:get_definition()
  if #attribute_definitions == 0 and next(attribute_definitions) ~= nil then
    set_attr(attribute_definitions, content)
  else
    for i, attr in ipairs(attribute_definitions) do
      set_attr(attr, content[i])
    end
  end
  return element
end


local Citation = Type:new("Citation")


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



local Inline = Element:new{type = "Inline"}

function Inline:new(o)
  o.type = o.type or o.t
  assert(type(o.type) == "string", "No element type was specified")
  setmetatable(o, self)
  self.__index = self
  return o
end

local NullaryInline = Nullary(Inline)
Inline.definitions = {
  Cite        = {{citations = Citations}, {content = Text}},
  Code        = {{attributes = Attributes}, {content = Text}},
  Emph        = {content = List(Inline)},
  Image       = {{attributes = Attributes}, {content = List(Inline)},
                 {{src = Text}, {title = Text}}},
  Link        = {{attributes = Attributes}, {content = List(Inline)},
                 {{src = Text}, {title = Text}}},
  LineBreak   = Nullary(Inline):new "LineBreak",
  Math        = {{format = MathType}, {content = Text}},
  Note        = {content = Blocks},
  Quoted      = {{quote_type = QuoteType}, {content = List(Inline)}},
  RawInline   = {{format = Text}, {content = Text}},
  SmallCaps   = {content = List(Inline)},
  SoftBreak   = Nullary(Inline):new "SoftBreak",
  Space       = NullaryInline:new "Space",
  Span        = {{attributes = Attributes}, {content = List(Inline)}},
  Str         = {content = Text},
  Strikeout   = {content = List(Inline)},
  Strong      = {content = List(Inline)},
  Subscript   = {content = List(Inline)},
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

function Inline:validate()
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

  for key,_ in pairs(flattened(self.get_definition(self.type))) do
    if type(key) == "string" and self[key] == nil then
      error("Required key '" .. key .. "' was not found.")
    end
  end
  return true
end

function Inline.__tostring(element)
  local eldef = element:get_definition()
  local buffer = {element.type}
  if #eldef == 0 and element.content then
    buffer[#buffer + 1] = ' '
    buffer[#buffer + 1] = tostring(element.content)
  else
    local attr_list = {}
    for i, _ in ipairs(eldef) do
      table.insert(attr_list, tostring(element[i]))
    end
    buffer[#buffer + 1] = table.concat(attr_list, ',')
  end
  return table.concat(buffer)
end

-- Constructors
Inline.constructors = {}
for eltype, definition in pairs(Inline.definitions) do
  Inline.constructors[eltype] = function (...)
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


local M = {
  _version = _version,
  MathType = MathType,
  Text = Text,
  Nullary = Nullary,
  Inline = Inline
}

local mt = {
  -- export constructors on base level
  __index = Inline.constructors
}
setmetatable(M, mt)

return M
