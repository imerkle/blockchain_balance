defmodule BlockchainBalanceWeb.XlmController do
    use BlockchainBalanceWeb, :controller

    def post_tx(conn, %{"tx" => tx, "ticker"=> ticker}) do
        api = @coins[ticker][api]
        BlockchainBalance.Blockchain.post(api, %{"tx"=> tx})
        json(conn, %{})
    end
end