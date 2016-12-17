-- This is a custom JSON writer for pandoc. It is inteded to be used in place of
-- a filter, if no other filtering package is available.
--
-- Invoke with: pandoc -t panlunatic.lua

json = require("dkjson")

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
function Blocksep()
  return ","
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add('"blocks":[' .. body .. ']')
  add('"pandoc-api-version":[1,17,0,4]')
  add('"meta":' .. Meta(metadata) .. '')
  return "{" .. table.concat(buffer,',') .. '}\n'
end

function Meta(metadata)
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

function Str(s)
  return json.encode({t = 'Str', c = s}) .. ","
end

function Space()
  return type_str('Space') .. ","
end

function SoftBreak()
  return json.encode({t = 'SoftBreak'}) .. ","
end

function LineBreak()
  return json.encode({t = 'LineBreak'}) .. ","
end

function Emph(s)
  return '{"t":"Emph","c":[' .. s:sub(1, -2) .. ']},'
end

function Strong(s)
  return '{"t":"Strong","c":[' .. s:sub(1, -2) .. ']},'
end

function Subscript(s)
  return '{"t":"Subscript","c":[' .. s:sub(1, -2) .. ']},'
end

function Superscript(s)
  return '{"t":"Superscript","c":[' .. s:sub(1, -2) .. ']},'
end

function SmallCaps(s)
  return '{"t":"SmallCaps","c":[' .. s:sub(1, -2) .. ']},'
end

function Strikeout(s)
  return '{"t":"Strikeout","c":[' .. s:sub(1, -2) .. ']},'
end

function Quoted(quote, s)
  return '{"t":"Quoted","c":[' .. type_str(quote) .. ',[' .. s:sub(1,-2) .. ']]},'
end

function SingleQuoted(s)
  return Quoted("SingleQuote", s)
end

function DoubleQuoted(s)
    return Quoted("DoubleQuote", s)
end

function Link(s, src, tit, attr)
  srctit = json.encode(src) .. ',' .. json.encode(tit)
  return '{"t":"Link","c":[' .. attributes(attr) .. ",[" .. s:sub(1, -2) .. '],['.. srctit .. ']]},'
end

function Image(s, src, tit, attr)
  srctit = json.encode(src) .. ',' .. json.encode(tit)
  return '{"t":"Image","c":[' .. attributes(attr) .. ",[" .. s:sub(1, -2) .. '],['.. srctit .. ']]},'
end

function Code(s, attr)
  return '{"t":"Code","c":[' .. attributes(attr) .. ',' .. json.encode(s) .. ']},'
end

function InlineMath(s)
  return '{"t":"Math","c":[{"t":"InlineMath"},' .. json.encode(s) .. ']},'
end

function DisplayMath(s)
  return '{"t":"Math","c":[{"t":"DisplayMath"},' .. json.encode(s) .. ']},'
end

function Note(s)
  return '{"t":"Note","c":[' .. s .. ']},'
end

function Span(s, attr)
  return '{"t":"Span","c":[' .. attributes(attr) .. ",[" .. s:sub(1, -2) .. ']]},'
end

function RawInline(format, str)
  return '{"t":"RawInline","c":[' .. json.encode(format) .. ',' .. json.encode(str) .. ']},'
end

function Cite(s, cs)
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

function Plain(s)
  return '{"t":"Plain","c":[' .. s:sub(1, -2) .. ']}'
end

function Para(s)
  return '{"t":"Para","c":[' .. s:sub(1, -2) .. ']}'
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
  return '{"t":"Header","c":[' .. lev .. "," .. attributes(attr) .. ',[' .. s:sub(1, -2) .. ']]}'
end

function BlockQuote(s)
  return '{"t":"BlockQuote","c":[' .. s .. ']}'
end

function HorizontalRule()
  return '{"t":"HorizontalRule"}'
end

function LineBlock(ls)
  lines = {}
  for _,l in ipairs(ls) do
    table.insert(lines, "[" .. l:sub(1, -2) .. "]")
  end
  return '{"t":"LineBlock","c":[' .. table.concat(lines, ',') .. ']}'
end

function CodeBlock(s, attr)
  return '{"t":"CodeBlock","c":[' .. attributes(attr) .. "," .. json.encode(s) .. ']}'
end

function BulletList(items)
  buffer = {}
  for _,item in ipairs(items) do
    table.insert(buffer, '[' .. item .. ']' )
  end
  return '{"t":"BulletList","c":[' .. table.concat(buffer, ',') .. ']}'
end

function OrderedList(items, num, sty, delim)
  item_strings = {}
  for _,item in ipairs(items) do
    table.insert(item_strings, '[' .. item .. ']')
  end
  listAttrs = {num, {t = sty}, {t = delim}}
  return '{"t":"OrderedList","c":[' .. json.encode(listAttrs) ..
    ',[' .. table.concat(item_strings, ',') .. ']]}'
end

function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer,"[[" .. k:sub(1, -2) .. "],[[" ..
                        table.concat(v,"],[") .. "]]]")
    end
  end
  return '{"t":"DefinitionList","c":[' .. table.concat(buffer, ',') .. "]}"
end

function CaptionedImage(src, tit, caption, attr)
  return Para(Image(caption, src, tit, attr):sub(1, -1))
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
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

function RawBlock(format, str)
  return '{"t":"RawBlock","c":[' .. json.encode(format) .. ',' .. json.encode(str) .. ']}'
end

function Div(s, attr)
  return '{"t":"Div","c":[' .. attributes(attr) .. ',[' .. s .. ']]}'
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)
