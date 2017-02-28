package = "panlunatic"
version = "1.0.0-1"

source = {
  url = "git://github.com/tarleb/panlunatic",
  tag = "v1.0.0",
}

description = {
  summary = "Custom json writer for portable pandoc filtering",
  homepage = "https://github.com/tarleb/panlunatic",
  license = "ISC",
}

dependencies = {
  "lua >= 5.1",
  "dkjson >= 1.0",
}

build = {
  type = "builtin",
  modules = {
    panlunatic = "src/panlunatic.lua",
  },
}