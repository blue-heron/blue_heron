defmodule BlueHeronTransportUSB.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/smartrent/blue_heron/tree/main/blue_heron_transport_usb"

  def project do
    [
      app: :blue_heron_transport_usb,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
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
      {:blue_heron, path: "../blue_heron"},
      {:elixir_make, "~> 0.6.0", runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2", only: :test, runtime: false}
    ]
  end

  defp description() do
    "BlueHeron Transport for USB-connected BT modules"
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
        "Makefile",
        "README.md",
        "src/*.[ch]",
        "LICENSE",
        "NOTICE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
