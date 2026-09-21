# Testing

On-demand reference for `elixir-development`.

Read this when writing or reviewing ExUnit tests.

Use ExUnit conventions that match the project.

Prefer:

* `describe` blocks around a function or behavior.
* Clear test names describing observable behavior.
* Expression under test on the left and expected value on the right.
* Pattern matching assertions for tagged tuples.
* `setup` for repeated per-test data.
* `setup_all` only for shared expensive setup that is safe across tests.

Good:

```elixir
describe "parse/1" do
  test "returns ok tuple for valid input" do
    assert MyApp.Token.parse("abc") == {:ok, %MyApp.Token{value: "abc"}}
  end

  test "returns error for empty input" do
    assert {:error, :empty} = MyApp.Token.parse("")
  end
end
```

When reviewing tests, flag:

* Tests that depend on order.
* Tests that hide too much behind helpers.
* Tests that assert implementation details instead of behavior.
* Shared state that can leak between async tests.

