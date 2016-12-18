Panlunatic
==========

Usage:

    pandoc -t panlunatic.lua input.md | pandoc -f json -t OUTFORMAT

The `panlunatic.lua` script serves as an example and is intended to be copied or
modified. Define a new function to in your script to alter elements of a
specific type.

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
