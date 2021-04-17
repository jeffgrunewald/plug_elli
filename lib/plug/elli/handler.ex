defmodule Plug.Elli.Handler do
  @moduledoc false

  @behaviour :elli_handler

  alias Plug.Elli.Request

  @impl true
  def init(_req, _args), do: {:ok, :handover}

  @impl true
  def handle(req, {plug, plug_opts}) do
    conn =
      req
      |> Plug.Elli.Conn.conn()
      |> plug.call(plug_opts)
      |> maybe_close_stream()

    {Request.close_or_keepalive(req, conn.resp_headers), ""}
  end

  @impl true
  def handle_event(_event, _args, _config) do
    :ok
  end

  defp maybe_close_stream(%Plug.Conn{adapter: {_, %Request{stream_process: pid}}} = conn) when is_pid(pid) do
    :elli_request.close_chunk(pid)

    conn
  end

  defp maybe_close_stream(conn), do: conn
end
