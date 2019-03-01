use Mix.Config

config :blockchain_balance, BlockchainBalanceWeb.Endpoint,
  http: [:inet6, port: System.get_env("PORT")],
  secret_key_base: System.get_env("SECRET_KEY_BASE")
# Do not print debug messages in production
config :logger, level: :info

#wont have blockchain config here