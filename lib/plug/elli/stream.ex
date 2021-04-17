defmodule Plug.Elli.Stream do
  @moduledoc false

  import Plug.Elli.Request, only: [elli_req: 1]

  alias Plug.Elli.Request

  def init(elli_req(socket: socket) = request, status, headers) do
    headers = [
      Request.connection(request, headers),
      {"Transfer-Encoding", "chunked"}
      | headers
    ]

    :elli_http.send_response(request, status, headers, "")
    :elli_tcp.setopts(socket, active: :once)

    :elli_http.chunk_loop(socket)
  end
end
