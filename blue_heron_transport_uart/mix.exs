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
      docs: docs(),
      package: package(),
      preferred_cli_env: [
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
      {:circuits_uart, "~> 1.4"},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp description() do
    "Communicate with BLE modules via UART"
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
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Bluetooth Core Specification v5.2" =>
          "https://www.bluetooth.org/docman/handlers/downloaddoc.ashx?doc_id=478726"
      }
    ]
  end
end
