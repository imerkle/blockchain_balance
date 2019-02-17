defmodule BlockchainBalanceWeb.InfoChannel do
  use Phoenix.Channel

  alias BlockchainBalance.Blockchain

  def join("info", _message, socket) do
    {:ok, socket}
  end

  def handle_in("ping_balance", params, socket) do
    b(params["coins"], socket)
    {:noreply,socket}
  end
  def handle_in("ping_txs", params, socket) do
    base = if params["base"] == nil, do: params["rel"], else: params["base"]
    payload = Blockchain.get_txs(params["rel"], base, params["address"])
    broadcast(socket, "pong_txs", %{"txs"=> payload})
    {:noreply,socket}
  end
  defp b([head | tail], socket) do
    balance_list = Blockchain.get_balance(head["ticker"], head["address"])
    broadcast(socket, "pong_balance", %{"list"=> balance_list})
    b(tail, socket)
  end
  defp b([], _socket) do
  end  
end