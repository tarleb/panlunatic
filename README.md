Panlunatic
==========

[![github release](https://img.shields.io/github/release/tarleb/panlunatic.svg?label=current+release)](https://github.com/tarleb/panlunatic/releases)
[![license](https://img.shields.io/github/license/tarleb/panlunatic.svg?style=flat-square)](./LICENSE)
[![travis build status](https://img.shields.io/travis/tarleb/panlunatic/master.svg?style=flat-square)](https://travis-ci.org/tarleb/panlunatic)

Panlunatic writers are Lua scripts intended to be used instead of filters.
Pandoc includes its very own lua interpreter, so no other software than pandoc
is required to process a document AST via a panlunatic writer.


Installation
------------

An archive containing all required lua files can be downloaded from this
project's [GitHub release page](https://github.com/tarleb/panlunatic/releases).
It will usually be most convenient to simply unpack it directly into the
directory from which you run pandoc.

The lua interpreter must be able to find the files `panlunatic.lua` and
`dkjson.lua`.  Set the `LUA_PATH` environment variable if these files are not in
the current working directory.

    export LUA_PATH="/path/to/panlunatic/?.lua;;"

The library can then be included from custom pandoc writers via `require
"panlunatic"`.

Alternatively, panlunatic can also be installed
via [luarocks](https://luarocks.org/) by running

    luarocks install --local panlunatic


Usage
-----

The `examples/undiv.lua` and `examples/emph2strong.lua` scripts serve as
examples and are intended to be copied or modified.  Define a new function in
your script to alter elements of the element type with the same name. The
output of the script should be valid JSON describing a pandoc document. This
allows to read the result back into pandoc.

    pandoc -t examples/undiv.lua input.md | pandoc -f json -t OUTFORMAT


Examples
--------

The following will turn emphasised text into strong text:

    panluna = require("panlunatic")
    Emph = panluna.Strong
    setmetatable(_G, {__index = panluna})


Unwrap all contents from `Div` elements:

    panluna = require("panlunatic")
    function Div(s, attr)
      return s
    end
    setmetatable(_G, {__index = panlunatic})


Remove list items starting with "NOPE"; note the decoding of the JSON string
containing the list items:

    panluna = require("panlunatic")

    function BulletList(items)
      new_items = {}
      for _, item_str in pairs(items) do
        item = panlunatic.decode('[' .. item_str .. ']')
        if item[1].c[1].c ~= "NOPE" then
          table.insert(new_items, item_str)
        end
      end
      if #new_items == 0 then
        return ""
      end
      return panlunatic.BulletList(new_items)
    end

    setmetatable(_G, {__index = panlunatic})
