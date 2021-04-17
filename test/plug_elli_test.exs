defmodule PlugElliTest do
  use ExUnit.Case

  test "hello world" do
    start_supervised!({Plug.Elli, plug: Testing.Simple.Plug})

    {:ok, _code, _headers, ref} = :hackney.get("http://localhost:8080/hello")

    assert {:ok, "hello world"} == :hackney.body(ref)
  end
end
