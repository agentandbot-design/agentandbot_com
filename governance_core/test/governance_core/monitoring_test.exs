defmodule GovernanceCore.MonitoringTest do
  use GovernanceCore.DataCase

  alias GovernanceCore.Monitoring

  describe "comments" do
    test "add_comment/1 broadcasts comment" do
      # Subscribe to the topic
      Monitoring.subscribe()

      # Add a comment
      {:ok, comment} = Monitoring.add_comment(%{"content" => "Hello World", "author" => "Tester"})

      # Assert received message
      assert_receive {:new_comment, ^comment}
      assert comment.content == "Hello World"
      assert comment.author == "Tester"
    end

    test "list_recent_comments/0 returns comments" do
      {:ok, comment1} = Monitoring.add_comment(%{"content" => "First"})
      {:ok, comment2} = Monitoring.add_comment(%{"content" => "Second"})

      comments = Monitoring.list_recent_comments()

      # Since it pre-pends, second should be first in list
      assert length(comments) >= 2
      assert hd(comments) == comment2
      assert Enum.member?(comments, comment1)
    end
  end
end
