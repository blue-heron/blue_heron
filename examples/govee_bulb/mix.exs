defmodule BlueHeronExampleGovee.MixProject do
  use Mix.Project

  def project do
    [
      app: :blue_heron_example_govee,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:blue_heron, path: "../../blue_heron"},
      {:blue_heron_transport_usb, path: "../../blue_heron_transport_usb"},
      {:blue_heron_transport_uart, path: "../../blue_heron_transport_uart"}
    ]
  end
end
