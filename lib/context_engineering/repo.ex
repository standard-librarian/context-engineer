defmodule ContextEngineering.Repo do
  use Ecto.Repo,
    otp_app: :context_engineering,
    adapter: Ecto.Adapters.Postgres
end
