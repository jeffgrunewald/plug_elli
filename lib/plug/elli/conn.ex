defmodule Plug.Elli.Conn do
  @moduledoc false

  @behaviour Plug.Conn.Adapter

  require Logger

  import Plug.Elli.Request, only: [elli_req: 1]

  alias Plug.Elli.{Request, Stream}

  def conn(
        elli_req(
          path: path,
          raw_path: raw_path,
          headers: headers,
          method: method,
          scheme: scheme,
          host: host,
          port: port
        ) = req
      ) do
    %Plug.Conn{
      adapter: {__MODULE__, %Request{req: req, stream_process: nil}},
      host: host,
      method: to_string(method),
      owner: self(),
      path_info: path,
      port: port,
      remote_ip: :elli_request.peer(req),
      query_string: :elli_request.query_str(req),
      req_headers: downcase_headers(headers),
      request_path: request_path(raw_path),
      scheme: scheme
    }
  end

  @impl true
  def send_resp(%Request{req: req} = request, status, headers, body) do
    headers = [
      Request.connection(req, headers),
      {"content-length", to_string(byte_size(body))}
      | headers
    ]

    :ok = :elli_http.send_response(req, status, headers, body)

    {:ok, nil, request}
  end

  @impl true
  # FINISH
  def send_file(
        elli_req(socket: socket),
        _status,
        _headers,
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
  def send_chunked(%Request{req: req} = request, status, headers) do
    pid = spawn_link(Stream, :init, [req, status, headers])

    {:ok, nil, %{request | stream_process: pid}}
  end

  @impl true
  def chunk(%Request{stream_process: pid}, body) do
    :elli_request.send_chunk(pid, body)

    :ok
  end

  @impl true
  def read_req_body(%Request{req: elli_req(body: body)} = request, _opts) do
    {:ok, IO.iodata_to_binary(body), request}
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
  def get_peer_data(%Request{req: elli_req(socket: socket)}) do
    {ip, port} = peer_ip_and_port(socket)

    %{
      address: ip,
      port: port,
      ssl_cert: peercert(socket)
    }
  end

  @impl true
  def get_http_protocol(elli_req(version: {0, 9})), do: :"HTTP/0.9"
  def get_http_protocol(elli_req(version: {1, 0})), do: :"HTTP/1"
  def get_http_protocol(elli_req(version: {1, 1})), do: :"HTTP/1.1"

  defp downcase_headers(headers) do
    Enum.map(headers, fn {key, value} ->
      {String.downcase(key), value}
    end)
  end

  defp peer_ip_and_port(socket) do
    case :elli_tcp.peername(socket) do
      {:ok, {_address, _port} = peer} -> peer
      {:error, _} -> {:undefined, :undefined}
    end
  end

  defp peercert({:plain, _socket}), do: nil

  defp peercert({:ssl, socket}) do
    case :ssl.peercert(socket) do
      {:ok, cert} -> cert
      {:error, _} -> nil
    end
  end

  defp request_path(raw_path) do
    case :binary.split(raw_path, [<<"?">>]) do
      [path, _query] -> path
      [path] -> path
    end
  end
end
