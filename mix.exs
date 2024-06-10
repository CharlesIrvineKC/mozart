defmodule Mozart.MixProject do
  use Mix.Project

  def project do
    [
      app: :mozart,
      version: "0.2.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Mozart",
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  defp description() do
    """
    Mozart is a BPM platform written in Elixir. It is currently in active development, but it has sufficient
    functionality for the development of BPM POCs.
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :observer, :wx],
      mod: {Mozart.Application, []}
    ]
  end

  defp docs do
    [
     extra_section: "GUIDES",
     extras: extras()
    ]
  end

  defp extras do
    [
      "guides/intro_bpm.md",
      "guides/app_overview.md",
      "guides/first_process_execution.md",
      "guides/task_types.md",
      "guides/home_loan.md",
      "guides/event_types.md"
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
      {:nimble_parsec, "~> 1.4.0"},
      {:cubdb, "~> 2.0"},
      {:ex_doc, "~> 0.33", only: :dev, runtime: false},
    ]
  end

  defp package() do
    [
      name: "mozart",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/CharlesIrvineKC/mozart"}
    ]
  end
end
