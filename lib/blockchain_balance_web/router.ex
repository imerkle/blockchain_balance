defmodule BlockchainBalanceWeb.Router do
  use BlockchainBalanceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlockchainBalanceWeb do
    pipe_through :api
    
    get "/eos_account_name", EosController, :account_name
    
    get "/best_block_vet", VetController, :best_block
    post "/post_tx_vet", VetController, :post_tx
  end
end
