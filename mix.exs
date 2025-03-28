defmodule BlueHeron.MixProject do
  use Mix.Project

  @version "0.5.3"
  @source_url "https://github.com/blue-heron/blue_heron"

  def project do
    [
      app: :blue_heron,
      version: @version,
      elixir: "~> 1.17",
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

  def application() do
    [
      extra_applications: [:logger, :crypto],
      mod: {BlueHeron.Application, []}
    ]
  end

  defp deps() do
    [
      {:circuits_uart, "~> 1.5"},
      {:property_table, "~> 0.3.0 or ~> 0.2.6"},
      {:ex_doc, "~> 0.35", only: :docs, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: :test, runtime: false}
    ]
  end

  defp description() do
    "Use Bluetooth LE in Elixir"
  end

  defp dialyzer() do
    [
      flags: [:unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:mix]
    ]
  end

  defp docs() do
    [
      extras: [
        "README.md",
        "CHANGELOG.md",
        NOTICE: [title: "Notice"],
        LICENSE: [title: "License"]
      ],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package() do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSES/*",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml",
        "test"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" => "https://api.reuse.software/info/github.com/blue-heron/blue_heron"
      }
    ]
  end
end
