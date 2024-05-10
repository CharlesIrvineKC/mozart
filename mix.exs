defmodule Mozart.MixProject do
  use Mix.Project

  def project do
    [
      app: :mozart,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :observer, :wx],
      mod: {Mozart.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.9"},
      {:hackney, "~> 1.20"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.10"},
    ]
  end
end
