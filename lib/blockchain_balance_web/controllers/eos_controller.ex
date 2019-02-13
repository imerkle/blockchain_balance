defmodule BlockchainBalanceWeb.EosController do
    use BlockchainBalanceWeb, :controller

    def account_name(conn, %{"public_key" => public_key, "ticker"=> ticker}) do
        name = BlockchainBalance.Blockchain.get_eos_name(ticker, public_key)
        json(conn, %{"account_name"=>name})
    end     
end