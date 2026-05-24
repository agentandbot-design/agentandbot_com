defmodule KadroPlatformWeb.ViewHelpers do
  def initials(nil), do: "KA"

  def initials(name) do
    name
    |> String.split(" ", trim: true)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.slice(0, 2)
    |> String.upcase()
  end
end
