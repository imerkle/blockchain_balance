# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :blockchain_balance, BlockchainBalanceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+x+a33TcJjQ52QPr0UVv8AWu+HHzPxt+f3T5u9BiG2jSTqrIsjgsKy86Fw2mBTso",
  render_errors: [view: BlockchainBalanceWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: BlockchainBalance.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :blockchain_balance,
    coins: 
        %{
        "BTC" => %{
            "api" => "https://insight.bitpay.com/api",
        },
        "LTC" => %{
            "api" => "https://insight.litecore.io/api",
        },
        "DASH" => %{
            "api" => "https://insight.dash.org/api",
        },
        "ETH" => %{
            "api" => "https://mainnet.infura.io/v3/2294f3b338ad4524aa9186012810e412",
        },
        "VET" => %{
            "api" => "https://sync-mainnet.vechain.org",
            "api_tokens" => "https://tokenbalance.herokuapp.com/api/balance",
        },
        "NEO" => %{
            "api" => "https://api.neoscan.io/api/main_net/v1",  
        },
        "XRP" => %{
            "api" => "https://xrpnode.herokuapp.com/api",
            "node" => "main",
        }, 
        "NANO" => %{
            "api" => "http://35.227.18.245:7076/",
        },                
    }
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
