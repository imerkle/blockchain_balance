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
            "decimal" => 8,
        },
        "LTC" => %{
            "api" => "https://insight.litecore.io/api",
            "decimal" => 8,
        },
        "DASH" => %{
            "api" => "https://insight.dash.org/api",
            "decimal" => 8,
        },
        "ETH" => %{
            "api" => "https://mainnet.infura.io/v3/2294f3b338ad4524aa9186012810e412",
            "etherscan_api" => "https://api.etherscan.io/api",
            "etherscan_api_key" => "8FISWFNZET4P2J451BY5I5GERA5MZG34S2",
            "decimal" => 18
        },
        "VET" => %{
            "api" => "https://sync-mainnet.vechain.org",
            "api_tokens" => "https://tokenbalance.herokuapp.com/api/balance",
            "veforge_api" => "https://explore.veforge.com/api",
            "decimal" => 18,
        },
        "NEO" => %{
            "api" => "https://api.neoscan.io/api/main_net/v1",
            "decimal" => 0,
        },
        "XRP" => %{
            "api" => "https://xrpnode.herokuapp.com/api",
            "node" => "main",
            "decimal" => 6,
        }, 
        "NANO" => %{
            "api" => "http://35.227.18.245:7076/",
        },                
    }
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
