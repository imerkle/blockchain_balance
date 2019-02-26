defmodule BlockchainBalanceWeb.VetController do
    use BlockchainBalanceWeb, :controller

    def best_block(conn, %{"ticker"=>ticker}) do
        id = BlockchainBalance.Blockchain.get_best_block_vet(ticker)
        json(conn, %{"id"=>id})
    end
    def post_tx(conn, %{"ticker"=>ticker,"rawTx"=>rawTx}) do
        id = BlockchainBalance.Blockchain.post_tx_vet(ticker, rawTx)
        json(conn, %{"id"=>id})
    end     
end