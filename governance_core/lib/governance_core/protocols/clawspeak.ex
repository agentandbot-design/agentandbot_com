defmodule GovernanceCore.Protocols.ClawSpeak do
  @moduledoc """
  Implements the ClawSpeak binary protocol for agent-to-agent communication.
  Frame Format: [FROM:1][TO:1][OP:1][ARG_LEN:1][ARG:Var][CRC32:4]
  """

  defstruct [:from, :to, :op, :arg, :crc]

  @type t :: %__MODULE__{
          from: byte(),
          to: byte(),
          op: byte(),
          arg: binary(),
          crc: non_neg_integer()
        }

  @doc """
  Decodes a binary frame into a ClawSpeak struct.
  Returns {:ok, struct, rest} if successful, or {:error, reason}.
  """
  def decode(
        <<from::8, to::8, op::8, arg_len::8, arg::binary-size(arg_len), crc::32, rest::binary>>
      ) do
    payload = <<from::8, to::8, op::8, arg_len::8, arg::binary>>
    expected_crc = :erlang.crc32(payload)

    if crc == expected_crc do
      {:ok, %__MODULE__{from: from, to: to, op: op, arg: arg, crc: crc}, rest}
    else
      {:error, :crc_mismatch}
    end
  end

  def decode(<<_::binary>>), do: {:error, :incomplete_frame}
  def decode(_), do: {:error, :invalid_binary}

  @doc """
  Encodes a ClawSpeak struct into a binary frame.
  """
  def encode(%__MODULE__{from: from, to: to, op: op, arg: arg}) when is_binary(arg) do
    arg_len = byte_size(arg)

    if arg_len > 255 do
      {:error, :arg_too_long}
    else
      payload = <<from::8, to::8, op::8, arg_len::8, arg::binary>>
      crc = :erlang.crc32(payload)
      {:ok, <<payload::binary, crc::32>>}
    end
  end
end
