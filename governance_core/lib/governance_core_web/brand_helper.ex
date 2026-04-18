defmodule GovernanceCoreWeb.BrandHelper do
  @moduledoc """
  Token Contract (V7.1) → HTML data-attribute bridge.
  Translates brand and state assigns into CSS-selectable attributes.
  """

  @valid_brands ~w(ipcioglu harezm eny agent eany-core eany-online eany-info)
  @valid_states ~w(idle hover active processing success error)

  @doc """
  Generates data attributes for branding and interaction state.
  
  ## Examples
      iex> BrandHelper.brand_attrs("eny", "processing")
      [{"data-brand", "eny"}, {"data-state", "processing"}]
  """
  def brand_attrs(brand, state \\ "idle") do
    brand = if brand in @valid_brands, do: brand, else: "agent"
    state = if state in @valid_states, do: state, else: "idle"
    
    [{"data-brand", brand}, {"data-state", state}]
  end
end
