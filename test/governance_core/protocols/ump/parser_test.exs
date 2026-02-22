defmodule GovernanceCore.Protocols.UMP.ParserTest do
  use ExUnit.Case, async: true
  alias GovernanceCore.Protocols.UMP.Parser

  describe "parse_frame/1" do
    test "successfully parses an image start frame with ID" do
      # [FROM: 01][TO: 02][OP: 0x10][ID: 07]
      binary_frame = <<1, 2, 0x10, 7>>
      assert {:ok, result} = Parser.parse_frame(binary_frame)
      assert result.from == 1
      assert result.to == 2
      assert result.op == :image_start
      assert result.id == 7
    end

    test "successfully parses a video end frame with ID and CRC32 hash" do
      # [FROM: 01][TO: 02][OP: 0x22][ID: 09][HASH: 0xDEADBEEF]
      binary_frame = <<1, 2, 0x22, 9, 0xDEADBEEF::32>>
      assert {:ok, result} = Parser.parse_frame(binary_frame)
      assert result.from == 1
      assert result.to == 2
      assert result.op == :video_end
      assert result.id == 9
      assert result.hash == 0xDEADBEEF
    end

    test "successfully parses an ID change frame" do
      # [FROM: 01][TO: 255][OP: 0x40][NEW_ID: 0x09]
      binary_frame = <<1, 255, 0x40, 9>>
      assert {:ok, result} = Parser.parse_frame(binary_frame)
      assert result.from == 1
      assert result.to == 255
      assert result.op == :id_change
      assert result.new_id == 9
    end

    test "returns error for an invalid opcode" do
      # [FROM: 01][TO: 02][OP: 0xFF][ID: 07]
      binary_frame = <<1, 2, 0xFF, 7>>
      assert {:error, :malformed_payload} = Parser.parse_frame(binary_frame)
    end

    test "returns error for a completely malformed frame" do
      # Too short
      binary_frame = <<1, 2>>
      assert {:error, :invalid_frame_format} = Parser.parse_frame(binary_frame)
    end
  end
end
