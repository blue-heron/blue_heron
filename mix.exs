defmodule Bluetooth.MixProject do
  use Mix.Project

  def project do
    [
      app: :bluetooth,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:harald, path: "../harald"},
      {:elixir_make, "~> 0.6.0", runtime: false},
      {:circuits_uart, "~> 1.4", optional: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:dev), do: ["./lib", "./examples"]
  defp elixirc_paths(:test), do: ["./lib", "./test/support"]
  defp elixirc_paths(_), do: ["./lib"]
end
