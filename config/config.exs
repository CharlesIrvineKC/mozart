import Config

config :mozart, Mozart.Repo,
  database: "mozart_repo",
  username: "postgres",
  password: "portgres",
  hostname: "localhost"

config :mozart, ecto_repos: [Mozart.Repo]
