local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt

-- Set up Elixir snippets
ls.add_snippets("elixir", {
  -- Function definition
  s("def", fmt([[
def {}({}) do
  {}{}
end
  ]], {
    i(1, "function_name"),
    i(2, ""),
    i(3, ""),
    i(0)
  })),

  -- Module definition
  s("defm", fmt([[
defmodule {} do
  {}{}
end
  ]], {
    i(1, "ModuleName"),
    i(2, ""),
    i(0)
  })),

  -- Private function definition
  s("defp", fmt([[
defp {}({}) do
  {}{}
end
  ]], {
    i(1, "function_name"),
    i(2, ""),
    i(3, ""),
    i(0)
  })),

  -- Case statement
  s("case", fmt([[
case {} do
  {} ->
    {}{}
end
  ]], {
    i(1, "expression"),
    i(2, "pattern"),
    i(3, ""),
    i(0)
  })),

  -- If statement
  s("if", fmt([[
if {} do
  {}
else
  {}{}
end
  ]], {
    i(1, "condition"),
    i(2, ""),
    i(3, ""),
    i(0)
  })),

  -- Pipe operator
  s("pipe", fmt([[
{}
|> {}{}
  ]], {
    i(1, "expression"),
    i(2, "function"),
    i(0)
  })),

  -- Documentation
  s("doc", fmt([[
@doc """
{}

## Parameters

  - {}: {}

## Examples

    iex> {}
    {}
"""
{}
  ]], {
    i(1, "Description"),
    i(2, "param"),
    i(3, "Description"),
    i(4, "example_code"),
    i(5, "result"),
    i(0)
  })),

  -- ExUnit test
  s("test", fmt([[
test "{}" do
  {}{}
end
  ]], {
    i(1, "test_description"),
    i(2, ""),
    i(0)
  })),
})
