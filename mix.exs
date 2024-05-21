defmodule Mozart.MixProject do
  use Mix.Project

  def project do
    [
      app: :mozart,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Mozart",
      description: description(),
      package: package()
    ]
  end

  defp description() do
    """
    Mozart is a BPM platform written in Elixir. It is currently in active development, but it has sufficient
    functionality for at least experimental use. Before the end of the year, a programming language
    independent process modeling language will be introduced. It will be much more readable than the
    native Elixir struct-based modeling language.
    """
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
      {:phoenix_pubsub, "~> 2.1"},
      {:tablex, "~> 0.3.1"},
      {:nimble_parsec, "~> 1.4.0"}
    ]
  end

  defp package() do
    [
      name: "mozart",
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/CharlesIrvineKC/mozart"}
    ]
  end
end
