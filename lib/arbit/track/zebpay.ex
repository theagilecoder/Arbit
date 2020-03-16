defmodule Arbit.Track.Zebpay do
  @moduledoc """
  This module calls Zebpay API and prepares list of %Zebpay{} structs
  """

  use Ecto.Schema
  alias Arbit.Track
  alias __MODULE__

  schema "zebpay" do
    field :coin,           :string
    field :quote_currency, :string
    field :price_usd,      :float
    field :price_inr,      :float
    field :price_btc,      :float
    field :volume,         :float

    timestamps()
  end

  @doc """
    Returns list of %Zebpay{} structs with all fields filled
  """
  def fetch_portfolio do
    conversion_amount = Track.get_conversion_amount("USD-INR")

    product_list()
    |> filter_relevant_pairs()
    |> Enum.map(&create_zebpay_struct/1)
    |> Enum.map(&fill_blank_price_inr(&1, conversion_amount))
    |> Enum.map(&fill_blank_price_usd(&1, conversion_amount))
  end

  # Parses API response
  defp product_list do
    %{body: body} = HTTPoison.get! url()
    Jason.decode!(body, [keys: :atoms])
    # |> Map.keys() |> Enum.sort() |> IO.inspect(limit: :infinity, width: 0)
  end

  defp url do
    "https://www.zebapi.com/pro/v1/market"
  end

  defp filter_relevant_pairs(pairs) do
    pairs
    |> Enum.filter(& &1.currency in ["USDT", "BTC", "INR"])
  end

  # Given a coin map, Create a %Zebpay{} struct
  defp create_zebpay_struct(map) do
    %Zebpay{}
    |> struct(%{coin:           map.virtualCurrency})
    |> struct(%{quote_currency: map.currency})
    |> struct(%{volume:    (if is_number(map.volume), do: map.volume/1, else: map.volume |> Float.parse() |> elem(0))})
    |> struct(%{price_inr: (if map.currency == "INR",  do: map.buy |> Float.parse() |> elem(0), else: nil)})
    |> struct(%{price_btc: (if map.currency == "BTC",  do: map.buy |> Float.parse() |> elem(0), else: nil)})
    |> struct(%{price_usd: (if map.currency == "USDT", do: map.buy |> Float.parse() |> elem(0), else: nil)})
  end

  defp fill_blank_price_inr(%Zebpay{price_usd: price_usd} = coin, conversion_amount) do
    cond do
      price_usd != nil -> struct(coin, %{price_inr: price_usd * conversion_amount})
      true             -> coin
    end
  end

  defp fill_blank_price_usd(%Zebpay{price_inr: price_inr} = coin, conversion_amount) do
    cond do
      price_inr != nil -> struct(coin, %{price_usd: price_inr / conversion_amount})
      true             -> coin
    end
  end
end
