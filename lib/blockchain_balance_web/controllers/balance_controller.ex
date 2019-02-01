defmodule BlockchainBalanceWeb.BalanceController do
  use BlockchainBalanceWeb, :controller
  require Logger
  
  @coins Application.get_env(:blockchain_balance, :coins)

  def balance(conn, params) do
    balances = b(0, params["coins"], %{})
	  json(conn, balances)
  end
  
  def txs(conn, params) do
    base = if params["base"] == nil, do: params["rel"], else: params["base"]
    t = get_txs({params["rel"], base}, params["address"])
	  json(conn, t)
  end

  defp b(i, coins, balances) do
    coin = Enum.at(coins, i)
    balance = get_balance(coin["ticker"], coin["address"])
    balances = Map.put(balances, coin["ticker"], balance)
    if i < length(coins) - 1 do
      b(i+1, coins, balances)
    end || balances
  end
  

  defp get_txs({rel, base}, address) do
    api = @coins[base]["api"]
    isToken = rel != base
    decimal = :math.pow(10, @coins[base]["decimal"])

    case base do
      n when n in ["BTC", "LTC", "DASH"] -> 
        response = get("#{api}/txs/?address=#{address}")
        for x <- response["txs"] do
          {kind, value} =  if Enum.at(x["vin"], 0)["addr"] != address do
            value = Enum.reduce(x["vout"], 0,fn x, acc -> 
              if Enum.at(x["scriptPubKey"]["addresses"], 0) == address do
                {v,_} = x["value"] |> Float.parse()
                acc + v
              end || acc
            end)
            {"got", value}
          else
            {value, _} = Enum.at(x["vout"], 0)["value"] |> Float.parse()
            {"sent", value}
          end
          %{
            "from"=> Enum.at(x["vin"], 0)["addr"],
            "hash"=> x["txid"],
            "confirmations"=> x["confirmations"],
            "value"=> value,
            "kind"=> kind,
            "fee"=> x["fees"],
            "timestamp" => x["blocktime"],
          }
        end
      "ETH" -> 
        action = if isToken, do: "tokentx", else: "txlist"
        etherscan_api = @coins[base]["etherscan_api"]
        etherscan_api_key = @coins[base]["etherscan_api_key"]

        response = get("#{etherscan_api}/?module=account&action=#{action}&address=#{address}&startblock=0&endblock=99999999&page=1&offset=10&sort=desc&apikey=#{etherscan_api_key}")
        for x <- response["result"] do
          {v, _} = x["value"] |> Float.parse()
          value = if isToken, do: v / :math.pow(10, x["tokenDecimal"] |> Float.parse() |> elem(0) ), else: v / decimal
          kind = if x["from"] |> String.downcase() == address |> String.downcase(), do: "sent", else: "got"
          %{
            "from" => x["from"],
            "hash" => x["hash"],
            "confirmations" => x["confirmations"] |> Integer.parse() |> elem(0),
            "value" => value,
            "kind" => kind,
            "fee" => elem(x["gas"] |> Float.parse, 0) * elem(x["gasPrice"] |> Float.parse, 0) / decimal,
            "timestamp" => x["timeStamp"] |> Integer.parse() |> elem(0),
          }
        end
      "VET" ->
        veforge_api = @coins[base]["veforge_api"]
        asset = if !isToken, do: nil, else: @coins[base]["assets"][rel]
        path = if !isToken, do: "transactions", else: "tokenTransfers"
        response = get("#{veforge_api}/#{path}?address=#{address}&count=10&offset=0")
        IO.inspect response[path] |> Enum.at(0)
        for x <- response[path] do
          if base == rel or asset["hash"] == x["contractAddress"] and x["transaction"]["reverted"] != nil do
            hash = if !isToken, do: x["id"], else: x["txId"]
            value = if !isToken, do: x["totalValue"], else: x["amount"]
            kind = if x["origin"] == address, do: "sent", else: "got"
            %{
                "from" => x["origin"],
                "hash" => hash,
                "value" => value / decimal,
                "kind" => kind,
                "fee" => 0,
                "timestamp" => x["timestamp"],
            }
          end
        end
      "NEO" ->
        response = get("#{api}/get_address_abstracts/#{address}/0")
        for x <- response["entries"] do
          kind = if x["address_from"] |> String.downcase()  == address |> String.downcase(), do: "sent", else: "got"
          %{
            from: x["address_from"],
            hash: x["txid"],
            confirmations: 1,
            value: x["amount"] |> Float.parse() |> elem(0),
            kind: kind,
            fee: 0,
            timestamp: x["time"],
          }
        end
      "XRP" -> 
        node = @coins[base]["node"]
        response = get("#{api}/account_tx?node=#{node}&address=#{address}&limit=10")
        for x <- response["result"]["transactions"] do
            kind = if x["tx"]["Account"] |> String.downcase() == address |> String.downcase(), do: "sent", else: "got"
            %{
              "from" => x["tx"]["Account"],
              "hash" => x["tx"]["hash"],
              "confirmations" => 1,
              "value" => (x["tx"]["Amount"] |> Float.parse() |> elem(0)) / decimal,
              "kind" => kind,
              "fee" => x["tx"]["Fee"] |> Float.parse() |> elem(0),
              #https://github.com/ripple/ripple-lib/issues/41
              "timestamp" => x["tx"]["date"] + 946684800,
            }
        end
      "NANO" ->
        response = post(api, %{ "action" => "account_history", "count" => 10, "account" => address })
        for x <- response["history"] do
          kind = if x["type"] == "send", do: "sent", else: "got"
          from = x["type"] == "send", do: address, else: x["account"]
          %{
            "from" => from,
            "hash" => x["hash"],
            "value" => (x["amount"] |> Float.parse() |> elem(0)) / decimal,
            "kind" => kind,
            "fee" => 0,
            "timestamp" => nil,
          }
        end
    data.data.history.map((o) => {
        const tx: TransactionType = ;
        txs.push(tx);
    });        
    end
  end
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
        body = %{"action"=> "account_balance", "account" => address}
        post(api, body)
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
    }

    response = post(url, body)
    response["result"]
  end
  defp get(url) do
    response = HTTPoison.get!(url)
    response.body |> Jason.decode!
  end
  defp post(url, body) do
    response = HTTPoison.post!(url, body |> Jason.encode!, [{"Content-Type", "application/json"}])
    response.body |> Jason.decode!
  end

  defp hex_to_integer("0x"<>string) do
    :erlang.binary_to_integer(string, 16)
  end  
end