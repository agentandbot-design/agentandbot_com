# GENERATED TOKENS — DO NOT EDIT MANUALLY
defmodule GovernanceCoreWeb.Tokens do
  @brand_ipcioglu %{h: 355, s: 78, l: 56}
  @brand_harezm %{h: 324, s: 71, l: 30}
  @brand_eny %{h: 72, s: 98, l: 54}
  @brand_agent %{h: 256, s: 100, l: 73}
  @brand_eany_core %{h: 72, s: 98, l: 54}
  @brand_eany_online %{h: 355, s: 78, l: 56}
  @brand_eany_info %{h: 324, s: 71, l: 30}

  def get_brand(brand) do
    case brand do
      "ipcioglu" -> @brand_ipcioglu
      "harezm" -> @brand_harezm
      "eny" -> @brand_eny
      "agent" -> @brand_agent
      "eany-core" -> @brand_eany_core
      "eany-online" -> @brand_eany_online
      "eany-info" -> @brand_eany_info
      _ -> @brand_harezm
    end
  end
end
