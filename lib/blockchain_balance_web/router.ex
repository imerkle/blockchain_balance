defmodule BlockchainBalanceWeb.Router do
  use BlockchainBalanceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlockchainBalanceWeb do
    pipe_through :api
    
    get "/eos_account_name", EosController, :account_name
  end
end
