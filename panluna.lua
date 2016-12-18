--
-- panluna.lua
--
-- Copyright (c) 2016 Albert Krewinkel
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the ISC license. See LICENSE for details.

local panluna = {_version = "0.0.1"}

local json = require("dkjson")

local function words(str)
  local t = {}
  local function helper(word)
    table.insert(t, word)
    return ""
  end
  if not str:gsub("%w+", helper):find("%S") then
    return t
  end
end

-- Helper function to convert an attributes table into json string
local function attributes(attr)
  classes = words(attr.class)
  kv = {}
  for k,v in pairs(attr) do
    if k ~= "id" and k ~= "class" then
      table.insert(kv, {k, v})
    end
  end
  return json.encode({attr.id, classes, kv})
end

local function type_str(str)
  return json.encode{t = str}
end

-- Blocksep is used to separate block elements.
function panluna.Blocksep()
  return ","
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
function panluna.Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add('"blocks":[' .. body .. ']')
  add('"pandoc-api-version":[1,17,0,4]')
  add('"meta":' .. Meta(metadata) .. '')
  return "{" .. table.concat(buffer,',') .. '}\n'
end

function panluna.Meta(metadata)
  local function is_list(v)
    if type(v) ~= "table" then return false end
    for k,_ in pairs(v) do
      if type(k) ~= "number" then
        return false
      end
    end
    return true
  end

  local function meta(data)
    local m = {}
    if data == nil then
      return '{}'
    elseif type(data) == 'string' then
      return '{"t":"MetaInlines","c":[' .. data:sub(1,-2) .. ']}'
    elseif type(data) == "bool" then
      return '{"t":"MetaBoolean","c":' .. data .. '}'
    elseif is_list(data) then
      for _,v in ipairs(data) do
        table.insert(m, meta(v))
      end
      return '{"t":"MetaList","c":[' .. table.concat(m, ',') .. ']}'
    else
      for k,v in pairs(data) do
        table.insert(m, json.encode(k) .. ":" .. meta(v))
      end
      return '{' .. table.concat(m, ',') .. '}'
    end
    return table.concat(m, ',')
  end

  return meta(metadata)
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function panluna.Str(s)
  return json.encode({t = 'Str', c = s}) .. ","
end

function panluna.Space()
  return type_str('Space') .. ","
end

function panluna.SoftBreak()
  return json.encode({t = 'SoftBreak'}) .. ","
end

function panluna.LineBreak()
  return json.encode({t = 'LineBreak'}) .. ","
end

function panluna.Emph(s)
  return '{"t":"Emph","c":[' .. s:sub(1, -2) .. ']},'
end

function panluna.Strong(s)
  return '{"t":"Strong","c":[' .. s:sub(1, -2) .. ']},'
end

function panluna.Subscript(s)
  return '{"t":"Subscript","c":[' .. s:sub(1, -2) .. ']},'
end

function panluna.Superscript(s)
  return '{"t":"Superscript","c":[' .. s:sub(1, -2) .. ']},'
end

function panluna.SmallCaps(s)
  return '{"t":"SmallCaps","c":[' .. s:sub(1, -2) .. ']},'
end

function panluna.Strikeout(s)
  return '{"t":"Strikeout","c":[' .. s:sub(1, -2) .. ']},'
end

function panluna.Quoted(quote, s)
  return '{"t":"Quoted","c":[' .. type_str(quote) .. ',[' .. s:sub(1,-2) .. ']]},'
end

function panluna.SingleQuoted(s)
  return Quoted("SingleQuote", s)
end

function panluna.DoubleQuoted(s)
    return Quoted("DoubleQuote", s)
end

function panluna.Link(s, src, tit, attr)
  srctit = json.encode(src) .. ',' .. json.encode(tit)
  return '{"t":"Link","c":[' .. attributes(attr) .. ",[" .. s:sub(1, -2) .. '],['.. srctit .. ']]},'
end

function panluna.Image(s, src, tit, attr)
  srctit = json.encode(src) .. ',' .. json.encode(tit)
  return '{"t":"Image","c":[' .. attributes(attr) .. ",[" .. s:sub(1, -2) .. '],['.. srctit .. ']]},'
end

function panluna.Code(s, attr)
  return '{"t":"Code","c":[' .. attributes(attr) .. ',' .. json.encode(s) .. ']},'
end

function panluna.InlineMath(s)
  return '{"t":"Math","c":[{"t":"InlineMath"},' .. json.encode(s) .. ']},'
end

function panluna.DisplayMath(s)
  return '{"t":"Math","c":[{"t":"DisplayMath"},' .. json.encode(s) .. ']},'
end

function panluna.Note(s)
  return '{"t":"Note","c":[' .. s .. ']},'
end

function panluna.Span(s, attr)
  return '{"t":"Span","c":[' .. attributes(attr) .. ",[" .. s:sub(1, -2) .. ']]},'
end

function panluna.RawInline(format, str)
  return '{"t":"RawInline","c":[' .. json.encode(format) .. ',' .. json.encode(str) .. ']},'
end

function panluna.Cite(s, cs)
  for _,cit in ipairs(cs) do
    cit.citationMode = {t = cit.citationMode}
    if cit.citationPrefix == "" then
      cit.citationPrefix = {}
    end
    if cit.citationSuffix == "" then
      cit.citationSuffix = {}
    end
  end
  return '{"t":"Cite","c":[' .. json.encode(cs) .. ",[" .. s:sub(1, -2) .. ']]},'
end

function panluna.Plain(s)
  return '{"t":"Plain","c":[' .. s:sub(1, -2) .. ']}'
end

function panluna.Para(s)
  return '{"t":"Para","c":[' .. s:sub(1, -2) .. ']}'
end

-- lev is an integer, the header level.
function panluna.Header(lev, s, attr)
  return '{"t":"Header","c":[' .. lev .. "," .. attributes(attr) .. ',[' .. s:sub(1, -2) .. ']]}'
end

function panluna.BlockQuote(s)
  return '{"t":"BlockQuote","c":[' .. s .. ']}'
end

function panluna.HorizontalRule()
  return '{"t":"HorizontalRule"}'
end

function panluna.LineBlock(ls)
  lines = {}
  for _,l in ipairs(ls) do
    table.insert(lines, "[" .. l:sub(1, -2) .. "]")
  end
  return '{"t":"LineBlock","c":[' .. table.concat(lines, ',') .. ']}'
end

function panluna.CodeBlock(s, attr)
  return '{"t":"CodeBlock","c":[' .. attributes(attr) .. "," .. json.encode(s) .. ']}'
end

function panluna.BulletList(items)
  buffer = {}
  for _,item in ipairs(items) do
    table.insert(buffer, '[' .. item .. ']' )
  end
  return '{"t":"BulletList","c":[' .. table.concat(buffer, ',') .. ']}'
end

function panluna.OrderedList(items, num, sty, delim)
  item_strings = {}
  for _,item in ipairs(items) do
    table.insert(item_strings, '[' .. item .. ']')
  end
  listAttrs = {num, {t = sty}, {t = delim}}
  return '{"t":"OrderedList","c":[' .. json.encode(listAttrs) ..
    ',[' .. table.concat(item_strings, ',') .. ']]}'
end

function panluna.DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer,"[[" .. k:sub(1, -2) .. "],[[" ..
                        table.concat(v,"],[") .. "]]]")
    end
  end
  return '{"t":"DefinitionList","c":[' .. table.concat(buffer, ',') .. "]}"
end

function panluna.CaptionedImage(src, tit, caption, attr)
  return Para(Image(caption, src, tit, attr):sub(1, -1))
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function panluna.Table(caption, aligns, widths, headers, rows)
  local content = {}
  local function add(s)
    table.insert(content, s)
  end

  local function row_string(cells)
    local res = {}
    for _,h in ipairs(cells) do
      table.insert(res, '[' .. h .. ']')
    end
    return '[' .. table.concat(res, ',') .. ']'
  end

  add('[' .. caption:sub(1, -2) .. ']')

  alignsTables = {}
  for _,align in ipairs(aligns) do
    table.insert(alignsTables, {t = align})
  end
  add(json.encode(alignsTables))

  add(json.encode(widths))

  add(row_string(headers))

  row_strings = {}
  for _, row in ipairs(rows) do
    table.insert(row_strings, row_string(row))
  end
  add('[' .. table.concat(row_strings, ',') .. ']')

  return '{"t":"Table","c":[' .. table.concat(content, ',')  .. ']}'
end

function panluna.RawBlock(format, str)
  return '{"t":"RawBlock","c":[' .. json.encode(format) .. ',' .. json.encode(str) .. ']}'
end

function panluna.Div(s, attr)
  return '{"t":"Div","c":[' .. attributes(attr) .. ',[' .. s .. ']]}'
end


local inline_types = {
  "Cite",
  "Code",
  "DisplayMath",
  "DoubleQuoted",
  "Emph",
  "Image",
  "InlineMath",
  "LineBreak",
  "Link",
  "Note",
  "RawInline",
  "SingleQuoted",
  "SmallCaps",
  "SoftBreak",
  "Space",
  "Span",
  "Str",
  "Strikeout",
  "Strong",
  "Subscript",
  "Superscript"
}

local is_inline = (function ()
  local inline_set = {}
  for _,v in ipairs(inline_types) do
    inline_set[v] = true
  end
  return function(elem)
    return inline_set[elem.t]
  end
end)()

panluna.encode = function(elem)
  if is_inline(elem) then
    return json.encode(elem) .. ','
  end
  return json.encode(elem)
end

panluna.decode = function(s)
  if s:sub(-2, -1) == ',' then
    return json.decode(s:sub(1, -2))
  end
  return json.decode(s)
end

return panluna
