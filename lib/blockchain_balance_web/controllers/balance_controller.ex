defmodule BlockchainBalanceWeb.BalanceController do
  use BlockchainBalanceWeb, :controller

  def balance(conn, params) do
    balances = b(0, params["coins"], %{})
	  json(conn, balances)
  end
  
  defp b(i, coins, balances) do
    coin = Enum.at(coins, i)
    balance = get_balance(coin["ticker"], coin["address"])
    balances = Map.put(balances, coin["ticker"], balance)
    balances = if i < length(coins) - 1 do
      b(i+1, coins, balances)
    end || balances
  end
  
  @coins Application.get_env(:blockchain_balance, :coins)
  defp get_balance(ticker, address) do
    api = @coins[ticker]["api"]
    case ticker do
      n when n in ["BTC", "LTC", "DASH"] -> 
        response = get("#{api}/addr/#{address}")
        response.balance
      "ETH" -> 
        response = json_rpc(api, "eth_getBalance", [address, "latest"])
        hex_to_integer(response)
      "NANO" -> 
        body = %{"action"=> "account_balance", "account" => address} |> Jason.encode!
        response = post(api, body)
      "VET" -> 
        response = get("#{api}/accounts/#{address}")
        hex_to_integer(response.balance)
      "XRP" ->
        node = @coins[ticker]["node"]
        response = get("#{api}/account_info/?node=#{node}&address=#{address}")
        response["result"]["account_data"]["Balance"]
      "NEO" ->
        response = get("#{api}/get_balance/#{address}");
        Enum.find(response["balance"], fn x -> x["asset_symbol"] == "NEO" end)["amount"]
      end
    end
    
  defp json_rpc(url, method, params) do
    body = %{
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => params,
      "id" => 1
    } |> Jason.encode!

    response = post(url, body)
    response["result"]
  end
  defp get(url) do
    response = HTTPoison.get!(url)
    response.body |> Jason.decode!
  end
  defp post(url, body) do
    response = HTTPoison.post!(url, body, [{"Content-Type", "application/json"}])
    response.body |> Jason.decode!
  end

  defp hex_to_integer("0x"<>string) do
    :erlang.binary_to_integer(string, 16)
  end  
end