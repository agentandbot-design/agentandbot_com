defmodule KadroPlatform.Identity do
  @moduledoc """
  Identity helpers for KADRO agents.

  Agents keep a human readable public id such as `KADRO-1001`, while internal
  records use a UUIDv7-compatible value so inserts remain time sortable.
  """

  def uuid_v7 do
    unix_ms = System.system_time(:millisecond)
    <<rand_a::12, rand_b::62, _::54>> = :crypto.strong_rand_bytes(16)

    <<uuid::128>> = <<unix_ms::48, 7::4, rand_a::12, 2::2, rand_b::62>>

    uuid
    |> Integer.to_string(16)
    |> String.pad_leading(32, "0")
    |> String.downcase()
    |> format_uuid()
  end

  def public_id(p_no) when is_binary(p_no), do: "KADRO-" <> p_no
  def public_id(p_no), do: p_no |> to_string() |> public_id()

  defp format_uuid(hex) do
    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
      e::binary-size(12)>> = hex

    Enum.join([a, b, c, d, e], "-")
  end
end
