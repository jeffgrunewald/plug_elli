defmodule Plug.Elli do
  @moduledoc """
  Adapter interface for the Elli webserver.
  """

  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one)
  end

  def http(plug, opts, elli_options \\ []) do
    run(:http, plug, opts, elli_options)
  end

  def https(plug, opts, elli_options \\ []) do
    Application.ensure_all_started(:ssl)
    run(:https, plug, opts, elli_options)
  end

  def shutdown(ref), do: :elli.stop(ref)

  def child_spec(opts) do
    scheme = Keyword.get(opts, :scheme, :http)

    {plug, plug_opts} =
      case Keyword.fetch!(opts, :plug) do
        {plug, plug_opts} -> {plug, plug.init(plug_opts)}
        plug -> {plug, plug.init([])}
      end

    {id, opts} = Keyword.pop(opts, :id)

    handler = [callback: Plug.Elli.Handler, callback_args: {plug, plug_opts}]

    elli_opts =
      opts
      |> Keyword.drop([:scheme, :plug, :options])
      |> Kernel.++(Keyword.get(opts, :options, []))
      |> normalize_elli_options(scheme)
      |> Keyword.merge(handler)

    %{
      id: id || build_id(plug, scheme),
      start: {:elli, :start_link, [elli_opts]}
    }
  end

  defp run(scheme, plug, opts, elli_opts) do
    handler = [callback: Plug.Elli.Handler, callback_args: {plug, opts}]

    elli_options =
      elli_opts
      |> normalize_elli_options(scheme)
      |> Keyword.merge(handler)
      |> Keyword.put_new(:name, build_id(plug, scheme))

    apply(:elli, :start_link, [elli_options])
  end

  defp normalize_elli_options(elli_opts, :http) do
    Keyword.put_new(elli_opts, :port, 8080)
  end

  defp normalize_elli_options(elli_opts, :https) do
    elli_opts
    |> Keyword.merge(ssl: true)
    |> Keyword.put_new(:port, 8443)
    |> Plug.SSL.configure()
    |> case do
         {:ok, options} -> options
         {:error, message} -> fail(message)
       end
  end

  defp build_id(plug, scheme) do
    Module.concat(plug, scheme |> to_string() |> String.upcase())
  end

  defp fail(message) do
    raise ArgumentError, "Unable to start Elli adapter, " <> message
  end
end
