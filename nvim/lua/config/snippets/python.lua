local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt

-- Set up Python snippets
ls.add_snippets("python", {
  -- Function definition
  s("def", fmt([[
def {}({}):
    {}{}
  ]], {
    i(1, "function_name"),
    i(2, ""),
    i(3, ""),
    i(0)
  })),

  -- Class definition
  s("class", fmt([[
class {}({}):
    def __init__(self, {}):
        {}{}
  ]], {
    i(1, "ClassName"),
    i(2, "object"),
    i(3, ""),
    i(4, ""),
    i(0)
  })),

  -- If statement
  s("if", fmt([[
if {}:
    {}{}
  ]], {
    i(1, "condition"),
    i(2, ""),
    i(0)
  })),

  -- For loop
  s("for", fmt([[
for {} in {}:
    {}{}
  ]], {
    i(1, "item"),
    i(2, "iterable"),
    i(3, ""),
    i(0)
  })),

  -- Try/except block
  s("try", fmt([[
try:
    {}
except {}:
    {}{}
  ]], {
    i(1, ""),
    i(2, "Exception"),
    i(3, ""),
    i(0)
  })),

  -- List comprehension
  s("lc", fmt("[{} for {} in {}{}]", {
    i(1, "item"),
    i(2, "item"),
    i(3, "iterable"),
    c(4, {
      t(""),
      fmt(" if {}", { i(1, "condition") })
    })
  })),

  -- Main pattern
  s("main", fmt([[
if __name__ == "__main__":
    {}{}
  ]], {
    i(1, ""),
    i(0)
  })),
})
