defmodule GovernanceCore.Protocols.UMP.Parser do
  @moduledoc """
  Parses Ultra Mini Agent Protocol (UMP) binary frames.

  UMP Frame Format:
  [FROM:1B][TO:1B][OP:1B][ID?:1B][HASH?:4B]
  """

  # Opcodes mapping
  # Image Start
  @op_is 0x10
  # Image Chunk
  @op_ic 0x11
  # Image End
  @op_ie 0x12
  # Video Start
  @op_vs 0x20
  # Video Chunk
  @op_vc 0x21
  # Video End
  @op_ve 0x22
  # Ack
  @op_ok 0x30
  # Error
  @op_er 0x31
  # ID Change
  @op_id 0x40

  @doc """
  Parses a raw binary frame and returns a map of the decoded components.
  """
  def parse_frame(<<from::8, to::8, op::8, rest::binary>>) do
    decode_op(from, to, op, rest)
  end

  def parse_frame(_invalid) do
    {:error, :invalid_frame_format}
  end

  # Chunk operations (Start/Chunk) expecting a 1-byte ID
  defp decode_op(from, to, op, <<id::8>>) when op in [@op_is, @op_ic, @op_vs, @op_vc] do
    {:ok, %{from: from, to: to, op: op_name(op), id: id}}
  end

  # End operations expecting a 1-byte ID and 4-byte CRC32 hash
  defp decode_op(from, to, op, <<id::8, hash::32>>) when op in [@op_ie, @op_ve] do
    {:ok, %{from: from, to: to, op: op_name(op), id: id, hash: hash}}
  end

  # Ack/Error operations expecting a 1-byte ID
  defp decode_op(from, to, op, <<id::8>>) when op in [@op_ok, @op_er] do
    {:ok, %{from: from, to: to, op: op_name(op), id: id}}
  end

  # ID Change operation expecting a 1-byte new ID
  defp decode_op(from, to, @op_id, <<new_id::8>>) do
    {:ok, %{from: from, to: to, op: :id_change, new_id: new_id}}
  end

  # Missing/extra data catch-all
  defp decode_op(_from, _to, _op, _rest) do
    {:error, :malformed_payload}
  end

  # Helper to convert opcodes to atoms for easier matching
  defp op_name(@op_is), do: :image_start
  defp op_name(@op_ic), do: :image_chunk
  defp op_name(@op_ie), do: :image_end
  defp op_name(@op_vs), do: :video_start
  defp op_name(@op_vc), do: :video_chunk
  defp op_name(@op_ve), do: :video_end
  defp op_name(@op_ok), do: :ack
  defp op_name(@op_er), do: :error
  defp op_name(@op_id), do: :id_change
  defp op_name(_), do: :unknown_opcode
end
