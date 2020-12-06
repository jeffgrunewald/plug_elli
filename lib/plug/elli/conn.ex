defmodule Plug.Elli.Conn do
  @moduledoc false

  require Logger

  @behaviour Plug.Conn.Adapter

  import Record, only: [defrecordp: 2, extract: 2]

  defrecordp :elli_req, extract(:req, from_lib: "elli/include/elli.hrl")

  def conn(
    elli_req(
      path: path,
      raw_path: raw_path,
      headers: headers,
      method: method,
      body: body,
      scheme: scheme,
      host: host,
      port: port,
      socket: socket
    ) = req
  ) do
    {peer_ip, _} = peer_ip_and_port(socket)

    [request_path, query_string] = :binary.split(raw_path, [<<"?">>])

    %Plug.Conn{
      adapter: {__MODULE__, req},
      host: host,
      method: method |> to_string(),
      owner: self(),
      path_info: path,
      port: port,
      remote_ip: peer_ip,
      query_string: query_string,
      req_headers: headers,
      request_path: request_path,
      scheme: scheme |> String.to_existing_atom()
    }
  end

  @impl true
  def send_resp(req, _status, _headers, _body) do
    {:ok, nil, req}
  end

  @impl true
  def send_file(
    elli_req(socket: socket) = req,
    status,
    headers,
    path,
    offset,
    length
  ) do
    length =
      cond do
        length == :all ->
          %File.Stat{type: :regular, size: size} = File.stat!(path)
          size
        is_integer(length) ->
          length
      end

    {:ok, file_descriptor} = File.open(path, [:read, :raw, :binary])
    req = :elli_tcp.sendfile(file_descriptor, socket, offset, length, [])
    {:ok, nil, req}
  end

  @impl true
  def send_chunked(req, _status, _headers) do
    {:ok, nil, req}
  end

  @impl true
  def chunk(req, _body) do
    :ok
  end

  @impl true
  def read_req_body(elli_req(body: body) = req, _opts) do
    {:ok, IO.iodata_to_binary(body), req}
  end

  @impl true
  def inform(_req, _status, _headers) do
    Logger.warn(fn -> "Informational calls are not supported by Elli" end)
    {:error, :not_supported}
  end

  @impl true
  def push(_req, _path, _headers) do
    Logger.warn(fn -> "HTTP/2 server push is not supported by Elli" end)
    {:error, :not_supported}
  end

  @impl true
  def get_peer_data(elli_req(socket: socket)) do
    {ip, port} = peer_ip_and_port(socket)

    %{
      address: ip,
      port: port,
      ssl_cert: nil
    }
  end

  @impl true
  def get_http_protocol(elli_req(version: {0, 9})), do: :"HTTP/0.9"
  def get_http_protocol(elli_req(version: {1, 0})), do: :"HTTP/1"
  def get_http_protocol(elli_req(version: {1, 1})), do: :"HTTP/1.1"
  def get_http_protocol(elli_req(version: {2, 0})), do: :"HTTP/2"

  defp peer_ip_and_port(socket) do
    case :elli_tcp.peername(socket) do
      {:ok, {address, port} = peer} -> peer
      {:error, _} -> {:undefined, :undefined}
    end
  end
end
