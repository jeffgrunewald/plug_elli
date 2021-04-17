defmodule PlugElliTest do
  use ExUnit.Case

  describe "simple plug" do
    test "hello world" do
      start_supervised!({Plug.Elli, plug: Testing.Simple.Plug})

      {:ok, _code, _headers, ref} = :hackney.get("http://localhost:8080/hello")

      assert {:ok, "hello world"} == :hackney.body(ref)
    end
  end

  describe "plug router" do
    setup do
      start_supervised!({Plug.Elli, plug: Testing.Plug.Router})

      :ok
    end

    test "get" do
      {:ok, _code, _headers, ref} = :hackney.get("http://localhost:8080/hello/jeff")

      assert {:ok, "jeff"} == :hackney.body(ref)
    end

    test "post" do
      payload = URI.encode_query(%{"name" => "jeff"})

      {:ok, _code, _headers, ref} =
        :hackney.post(
          "http://localhost:8080/create",
          [{"content-type", "application/x-www-form-urlencoded"}],
          payload
        )

      assert {:ok, "created jeff"} == :hackney.body(ref)
    end

    test "chunked" do
      {:ok, _code, _headers, ref} = :hackney.get("http://localhost:8080/chunks")

      assert {:ok, "onetwothreefourfivesix"} = :hackney.body(ref)
    end
  end
end
