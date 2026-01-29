# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :context_engineering,
  ecto_repos: [ContextEngineering.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :context_engineering, ContextEngineeringWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ContextEngineeringWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ContextEngineering.PubSub,
  live_view: [signing_salt: "5cFliIRC"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Nx backend configuration
config :nx, default_backend: EXLA.Backend

# Quantum scheduler
config :context_engineering, ContextEngineering.Scheduler,
  jobs: [
    # Run decay worker daily at 2 AM
    {"0 2 * * *", {ContextEngineering.Workers.DecayWorker, :run, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
