defmodule Mozart.Repo do
  use Ecto.Repo,
    otp_app: :mozart,
    adapter: Ecto.Adapters.Postgres
end

