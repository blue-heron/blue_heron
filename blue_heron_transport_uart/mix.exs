defmodule BlueHeronTransportUart.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/smartrent/blue_heron/tree/main/blue_heron_transport_uart"

  def project do
    [
      app: :blue_heron_transport_uart,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        credo: :test,
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # {:blue_heron, path: "../blue_heron"},
      {:blue_heron, "~> 0.1.0"},
      {:circuits_uart, "~> 1.4"},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2", only: :test, runtime: false}
    ]
  end

  defp description() do
    "BlueHeron Transport for UART-connected BT modules"
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs() do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package() do
    [
      files: [
        "lib",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "NOTICE",
        "CHANGELOG.md"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
