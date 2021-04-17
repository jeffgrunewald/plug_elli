defmodule PlugElli.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "A Plug adapter for Elli"

  def project do
    [
      app: :plug_elli,
      name: "PlugElli",
      version: "0.1.0",
      elixir: "~> 1.10",
      description: @description,
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      elixirc_paths: Mix.env() |> elixirc_paths()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Plug.Elli, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.11"},
      {:elli, "~> 3.3"},
      {:hackney, "~> 1.17", only: :test},
      {:jason, "~> 1.2", only: :test}
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2"],
      maintainers: ["Jeff Grunewald"],
      links: %{"GitHub" => "https://github.com/jeffgrunewald/plug_elli"}
    }
  end

  defp docs do
    [
      main: "Plug.Elli",
      source_ref: "v#{@version}",
      source_url: "https://github.com/jeffgrunewald/plug_elli"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
