defmodule BlockchainBalanceWeb.Router do
  use BlockchainBalanceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BlockchainBalanceWeb do
    pipe_through :api
    
  end
end
