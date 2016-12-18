Panlunatic
==========

Usage:

    pandoc -t panlunatic.lua input.md | pandoc -f json -t OUTFORMAT

The `panlunatic.lua` script serves as an example and is intended to be copied or
modified. Define a new function in your script to alter elements of a specific
type.

Examples
--------

The following will turn emphasised text into strong text:

    panluna = require("panluna")
    Emph = panluna.Strong
    setmetatable(_G, {__index = panluna})


Unwrap all contents from `Div` elements:

    panluna = require("panluna")
    function Div(s, attr)
      return s
    end
    setmetatable(_G, {__index = panluna})


Remove list items starting with "NOPE"; note the decoding of the JSON string
containing the list items:

    panluna = require("panluna")

    function BulletList(items)
      new_items = {}
      for _, item_str in pairs(items) do
        item = panluna.decode('[' .. item_str .. ']')
        if item[1].c[1].c ~= "NOPE" then
          table.insert(new_items, item_str)
        end
      end
      if #new_items == 0 then
        return ""
      end
      return panluna.BulletList(new_items)
    end

    setmetatable(_G, {__index = panluna})
