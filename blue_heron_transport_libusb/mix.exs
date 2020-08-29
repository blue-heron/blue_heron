defmodule BlueHeronTransportLibUSB.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/smartrent/blue_heron/tree/main/blue_heron_transport_libusb"

  def project do
    [
      app: :blue_heron_transport_libusb,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
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
      {:elixir_make, "~> 0.6.0", runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:blue_heron, path: "../blue_heron"}
    ]
  end

  defp description() do
    "Communicate with BLE modules via LibUSB"
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
