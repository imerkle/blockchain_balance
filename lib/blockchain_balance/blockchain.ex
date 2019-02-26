defmodule BlockchainBalance.Blockchain do
  

  @coins Application.get_env(:blockchain_balance, :coins) 
  
  def get_txs(rel, base, address) do
    api = if @coins[rel]!= nil, do: @coins[rel]["api"], else: @coins[base]["api"]
    isToken = rel != base
    decimal = :math.pow(10, @coins[base]["decimal"])

    case base do
      n when n in ["BTC", "LTC", "DASH"] -> 
        response = get("#{api}/txs/?address=#{address}")
        for x <- response["txs"] do
          {kind, value} =  if Enum.at(x["vin"], 0)["addr"] != address do
            value = Enum.reduce(x["vout"], 0,fn x, acc ->
              if x["scriptPubKey"]["addresses"]!=nil and Enum.at(x["scriptPubKey"]["addresses"], 0) == address do
                {v,_} = x["value"] |> Float.parse()
                acc + v
              end || acc
            end)
            {"got", value}
          else
            {value, _} = Enum.at(x["vout"], 0)["value"] |> Float.parse()
            {"sent", value}
          end
          from = if Enum.at(x["vin"], 0)["addr"] == nil, do: address, else: Enum.at(x["vin"], 0)["addr"]
          %{
            "from"=> from,
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
        blockscout_api = @coins[base]["blockscout_api"]

        response = get("#{blockscout_api}/?module=account&action=#{action}&address=#{address}&sort=desc")
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
            "fee" => elem(x["gasUsed"] |> Float.parse, 0) * elem(x["gasPrice"] |> Float.parse, 0) / decimal,
            "timestamp" => x["timeStamp"] |> Integer.parse() |> elem(0),
          }
        end
      "VET" ->
        veforge_api = @coins[base]["veforge_api"]
        asset = if !isToken, do: nil, else: Enum.filter(@coins[base]["assets"], fn x-> x["symbol"] == rel end) |> Enum.at(0)
        path = if !isToken, do: "transactions", else: "tokenTransfers"
        response = get("#{veforge_api}/#{path}?address=#{address}&count=10&offset=0")
        for x <- response[path] do
          if base == rel or asset["hash"] == x["contractAddress"] and x["transaction"]["reverted"] != nil do
            hash = if !isToken, do: x["id"], else: x["txId"]
            value = if !isToken, do: x["totalValue"], else: hex_to_integer(x["amount"])
            kind = if x["origin"] == address, do: "sent", else: "got"
            %{
                "from" => x["origin"],
                "hash" => hash,
                "value" => value / decimal,
                "kind" => kind,
                "fee" => 0,
                "timestamp" => x["timestamp"],
                "confirmations" => 1,                
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
              "value" => (x["tx"]["Amount"] |> Float.parse() |> elem(0)) / decimal,
              "kind" => kind,
              "fee" => x["tx"]["Fee"] |> Float.parse() |> elem(0),
              #https://github.com/ripple/ripple-lib/issues/41
              "timestamp" => x["tx"]["date"] + 946684800,
              "confirmations" => 1,
            }
        end
      "XLM" ->
        response = get("#{api}/accounts/#{address}/transactions?limit=5&order=desc")        
        for x <- response["_embedded"]["records"] do
          hash = x["id"]
          res = get("#{api}/transactions/#{hash}/operations?limit=1&order=desc")
          operation = res["_embedded"]["records"] |> Enum.at(0)
          amount = if operation["amount"] != nil, do: operation["amount"], else: operation["starting_balance"]
          kind = if x["source_account"] |> String.downcase() == address |> String.downcase(), do: "sent", else: "got"
          timestamp = x["created_at"] |> NaiveDateTime.from_iso8601!() |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()          
          %{
            "from" => x["source_account"],
            "hash" => hash,
            "value" => (amount |> Float.parse() |> elem(0)) / decimal,
            "kind" => kind,
            "fee" => x["fee_paid"],
            "timestamp" => timestamp,
            "confirmations" => 1,
          }
      end        
      "NANO" ->
        response = post(api, %{ "action" => "account_history", "count" => 10, "account" => address })
        for x <- response["history"] do
          kind = if x["type"] == "send", do: "sent", else: "got"
          from = if x["type"] == "send", do: address, else: x["account"]
          %{
            "from" => from,
            "hash" => x["hash"],
            "value" => (x["amount"] |> Float.parse() |> elem(0)) / decimal,
            "kind" => kind,
            "fee" => 0,
            "timestamp" => nil,
            "confirmations" => 1,            
          }
        end
      "EOS" ->
        response = post("#{api}/history/get_actions", %{ "account_name" => address, "pos" => -1, "offset" => -100 })
        txs = for x <- response["actions"] do
          from = x["action_trace"]["act"]["data"]["from"]
          kind = if from == address, do: "sent", else: "got"
          timestamp = x["block_time"] |> NaiveDateTime.from_iso8601!() |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
          %{
            "from" => from,
            "hash" => x["action_trace"]["trx_id"],
            "value" => (x["action_trace"]["act"]["data"]["quantity"] |> Float.parse() |> elem(0)),
            "kind" => kind,
            "fee" => 0,
            "timestamp" => timestamp,
            "confirmations" => 1,            
          }
        end
        txs |> Enum.reverse()
    end
  end
  def get_balance(ticker, address) do
    api = @coins[ticker]["api"]
    decimal = :math.pow(10, @coins[ticker]["decimal"])

    case ticker do
      n when n in ["BTC", "LTC", "DASH","BCH"] ->
        response = get("#{api}/addr/#{address}")
        [%{"rel"=> ticker, "balance" => response["balanceSat"] / decimal}]
      "ETH" ->
        response = json_rpc(api, "eth_getBalance", [address, "latest"])
        [%{"rel"=> ticker, "balance" => hex_to_integer(response)  / decimal }] ++ get_balance_tokens(ticker, address)
      "NANO" ->
        response = post(api, %{"action"=> "account_balance", "account" => address})
        [%{"rel"=> ticker, "balance" => response.balance, "pending"=> response.pending}]
      "VET" ->
        response = get("#{api}/accounts/#{address}")
        energy_decimal = :math.pow(10, @coins[ticker]["energy_decimal"])
        [
          %{"rel"=> ticker, "balance" => hex_to_integer(response["balance"])  / decimal },
          %{"rel"=>  @coins[ticker]["energy_ticker"], "balance" => hex_to_integer(response["energy"])  / energy_decimal },
        ]
      "XRP" ->
        node = @coins[ticker]["node"]
        response = get("#{api}/account_info/?node=#{node}&address=#{address}")
        b = response["result"]["account_data"]["Balance"] |> Float.parse() |> elem(0)
        [%{"rel"=> ticker, "balance" => b / decimal}]
      "XLM" ->
        response = get("#{api}/accounts/#{address}")
        balances = Enum.filter(response["balances"], fn x -> x["asset_type"] == "native" end) |> Enum.at(0)
        b = balances["balance"] |> Float.parse() |> elem(0)
        [%{"rel"=> ticker, "balance" => b  / decimal}]
      "NEO" ->
        response = get("#{api}/get_balance/#{address}");
        for x <- response["balance"] do
          %{"rel"=> x["asset_symbol"], "balance" => x["amount"]}
        end
      "EOS" ->
        response = post("#{api}/chain/get_currency_balance", %{"code"=> "eosio.token", "account" => address, "symbol"=> "EOS"})
        b = Enum.at(response, 0) |> Float.parse() |> elem(0)
        [%{"rel"=> ticker, "balance" => b  / decimal}]
    end
  end

  def get_balance_tokens(base, address) do 
    case base do
      "ETH" -> 
        blockscout_api = @coins[base]["blockscout_api"]
        response = get("#{blockscout_api}/?module=account&action=tokenlist&address=#{address}")
        for x <- response["result"] do
          d = x["decimals"] |> Integer.parse() |> elem(0)
          decimals = :math.pow(10, d)
          b = x["balance"] |> Float.parse() |> elem(0)          
          %{"rel"=> x["symbol"], "balance"=> b / decimals}
        end
      "VET" ->
        veforge_api = @coins[base]["veforge_api"]
        response = get("#{veforge_api}/account/#{address}/tokenBalances")
        assets = @coins[base]["assets"]
        for  {k, v}  <-  response  do
          asset = Enum.filter(assets, fn x -> x["hash"]==k end) |> Enum.at(0)
          decimals = :math.pow(10, asset["decimal"])
          b = v / decimals
          %{"rel"=> asset["symbol"], "balance"=> b}
        end

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
    result = response.body |> Jason.decode()
    case result do
      {:ok, decoded} -> decoded
      {:error, _} -> %{"result"=>[]}
    end
  end
  defp post(url, body, opts \\ [{"Content-Type", "application/json"}]) do
    response = HTTPoison.post!(url, body |> Jason.encode!, opts)
    result = response.body |> Jason.decode()
    case result do
      {:ok, decoded} -> decoded
      {:error, _} -> %{}
    end    
  end

  defp hex_to_integer("0x"<>string) do
    :erlang.binary_to_integer(string, 16)
  end


  def get_eos_name(ticker, public_key) do
    api = @coins[ticker]["api"]
    response = post("#{api}/history/get_key_accounts", %{"public_key"=> public_key})
    Enum.at(response["account_names"], 0)
  end
  def get_best_block_vet(ticker) do
    api = @coins[ticker]["api"]
    response = get("#{api}/blocks/best")
    response["id"]
  end
  def post_tx_vet(ticker, rawTx) do
    api = @coins[ticker]["api"]
    response = post("#{api}/transactions",%{"raw"=> rawTx})
    response["id"]
  end
end