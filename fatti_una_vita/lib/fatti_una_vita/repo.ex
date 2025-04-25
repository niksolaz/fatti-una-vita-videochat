defmodule FattiUnaVita.Repo do
  use Ecto.Repo,
    otp_app: :fatti_una_vita,
    adapter: Ecto.Adapters.SQLite3
end
