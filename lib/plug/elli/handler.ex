defmodule Plug.Elli.Handler do
  @moduledoc false

  import Record, only: [defrecordp: 2, extract: 2]

  defrecordp :req, extract(:req, from_lib: "elli/include/elli.hrl")

  @behaviour :elli_handler

  @impl true
  def handle(
    req(
      method: method,
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      args: args,
      raw_path: raw_path,
      version: version,
      headers: headers,
      body: body,
      socket: socket
    ), _args) do
    request =
      %{
        args: args,
        body: body,
        headers: headers,
        host: host,
        method: method,
        path: path,
        port: port,
        raw_path: raw_path,
        scheme: scheme,
        socket: socket,
        version: version
      }
    IO.inspect(request, label: "MAP")
    {:ok, [], <<"Hello World!">>}
  end

  @impl true
  def handle_event(_event, _args, _config) do
    :ok
  end
end
