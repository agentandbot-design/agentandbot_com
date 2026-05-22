defmodule GovernanceCore.Payment.Blockchain do
  @moduledoc """
  Handles blockchain verification for USDC transactions via Alchemy RPC.
  Supported chains: base, arbitrum, polygon.
  """
  require Logger

  @usdc_contracts %{
    "base" => "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "arbitrum" => "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    "polygon" => "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
  }

  @transfer_topic "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

  def verify_transaction(tx_hash, chain, expected_wallet, expected_amount_usdc) do
    if System.get_env("MOCK_PAYMENTS") == "true" do
      Logger.info("[BLOCKCHAIN] MOCK MODE: Auto-verifying TX #{tx_hash}")
      {:ok, %{amount: Decimal.from_float(expected_amount_usdc), to: expected_wallet}}
    else
      with {:ok, rpc_url} <- get_alchemy_url(chain),
           {:ok, receipt} <- fetch_receipt(tx_hash, rpc_url),
           {:ok, transfer_log} <- find_usdc_transfer(receipt, chain, expected_wallet) do
        amount_hex = transfer_log["data"]
        amount_int = parse_hex(amount_hex)

        # USDC has 6 decimals
        # expected_amount_usdc is in USDC (e.g. 0.5)
        actual_amount = Decimal.div(amount_int, 1_000_000)

        if Decimal.compare(actual_amount, Decimal.from_float(expected_amount_usdc)) != :lt do
          {:ok, %{amount: actual_amount, to: expected_wallet}}
        else
          {:error, :insufficient_amount}
        end
      else
        err ->
          Logger.error("[BLOCKCHAIN] Verification failed: #{inspect(err)}")
          err
      end
    end
  end

  defp get_alchemy_url(chain) do
    env_var = "ALCHEMY_#{String.upcase(chain)}_URL"

    case System.get_env(env_var) do
      nil -> {:error, "Environment variable #{env_var} not set"}
      url -> {:ok, url}
    end
  end

  defp fetch_receipt(tx_hash, rpc_url) do
    body =
      Jason.encode!(%{
        jsonrpc: "2.0",
        id: 1,
        method: "eth_getTransactionReceipt",
        params: [tx_hash]
      })

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(rpc_url, body, headers) do
      {:ok, %{status_code: 200, body: res_body}} ->
        case Jason.decode!(res_body) do
          %{"result" => nil} -> {:error, :tx_not_found}
          %{"result" => result} -> {:ok, result}
          %{"error" => %{"message" => msg}} -> {:error, msg}
        end

      {:ok, %{status_code: code}} ->
        {:error, "RPC Error: #{code}"}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  defp find_usdc_transfer(receipt, chain, expected_wallet) do
    contract = Map.get(@usdc_contracts, chain)
    logs = receipt["logs"] || []

    # Topic 1 is 'from', Topic 2 is 'to'
    # Wallet address needs to be padded to 32 bytes (64 hex chars)
    expected_wallet_topic =
      "0x" <>
        String.pad_leading(
          String.replace(expected_wallet, "0x", "") |> String.downcase(),
          64,
          "0"
        )

    transfer =
      Enum.find(logs, fn log ->
        String.downcase(log["address"]) == String.downcase(contract) and
          Enum.at(log["topics"], 0) == @transfer_topic and
          Enum.at(log["topics"], 2) == expected_wallet_topic
      end)

    if transfer, do: {:ok, transfer}, else: {:error, :transfer_not_found}
  end

  defp parse_hex(nil), do: 0
  defp parse_hex("0x" <> hex), do: String.to_integer(hex, 16)
  defp parse_hex(hex), do: String.to_integer(hex, 16)
end
