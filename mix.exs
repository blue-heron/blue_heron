defmodule Bluetooth.MixProject do
  use Mix.Project

  def project do
    [
      app: :bluetooth,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      compilers: compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Bluetooth.Application, []}
    ]
  end

  def compilers do
    compilers = Mix.compilers()
    skip_libusb? = Application.get_env(:bluetooth, :skip_libusb) || System.get_env("SKIP_LIBUSB")

    if skip_libusb? do
      Mix.shell().info("""
      #{IO.ANSI.yellow()}warning:#{IO.ANSI.default_color()} Skipping LibUSB port compilation

      In most cases, this is okay.

      If you intend to use a USB bluetooth device for communication,
      then this must be enabled by removing it from your application config:

        #{IO.ANSI.cyan()}config :bluetooth, skip_libusb: false#{IO.ANSI.default_color()}

      Or by unsetting environment variable `SKIP_LIBUSB`

        #{IO.ANSI.cyan()}unset SKIP_LIBUSB#{IO.ANSI.default_color()}
      """)

      compilers
    else
      [:elixir_make | compilers]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:harald, path: "../harald"},
      {:elixir_make, "~> 0.6.0", runtime: false},
      {:ex_bin, "~> 0.4"},
      {:circuits_uart, "~> 1.4", optional: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:dev), do: ["./lib", "./examples"]
  defp elixirc_paths(:test), do: ["./lib", "./test/support"]
  defp elixirc_paths(_), do: ["./lib"]
end
