defmodule Plug.Elli.Request do
  @moduledoc false

  @connection_header "connection"

  import Record, only: [defrecord: 3, extract: 2]
  defrecord :elli_req, :req, extract(:req, from_lib: "elli/include/elli.hrl")

  @type t :: %__MODULE__{
          req: :elli.req(),
          stream_process: pid()
        }

  defstruct [:req, :stream_process]

  def close_or_keepalive(req, resp_headers) do
    case get_header(resp_headers, @connection_header) do
      :undefined ->
        case connection_token(req) do
          value when value in ["close", "Close"] -> :close
          _ -> :keep_alive
        end

      value when value in ["close", "Close"] ->
        :close

      value when value in ["Keep-Alive", "keep-alive"] ->
        :keep_alive
    end
  end

  def connection(req, resp_headers) do
    case get_header(resp_headers, @connection_header) do
      :undefined ->
        {@connection_header, connection_token(req)}

      _ ->
        []
    end
  end

  defp connection_token(elli_req(version: {1, 1}, headers: headers)) do
    case get_header(headers, @connection_header) do
      close when close in ["close", "Close"] ->
        "close"

      _ ->
        "Keep-Alive"
    end
  end

  defp connection_token(elli_req(version: {1, 0}, headers: headers)) do
    case get_header(headers, @connection_header) do
      "Keep-Alive" -> "Keep-Alive"
      _ -> "close"
    end
  end

  defp connection_token(elli_req(version: {0, 9})), do: "close"

  defp get_header(headers, key, default \\ :undefined) do
    case_folded_key = :string.casefold(key)

    Enum.find_value(headers, default, fn {key, value} ->
      case :string.equal(case_folded_key, key, true) do
        true -> value
        false -> false
      end
    end)
  end
end
