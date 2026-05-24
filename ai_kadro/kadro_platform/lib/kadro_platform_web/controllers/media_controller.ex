defmodule KadroPlatformWeb.MediaController do
  use KadroPlatformWeb, :controller

  @allowed_ext ~w(.png .jpg .jpeg .gif .webp .html)

  def show(conn, %{"path" => path_parts}) do
    rel_path = Path.join(path_parts)
    root = Application.fetch_env!(:kadro_platform, :media_root)
    requested = Path.expand(Path.join(root, rel_path))

    cond do
      not String.starts_with?(requested, root) ->
        send_resp(conn, 403, "Forbidden")

      Path.extname(requested) not in @allowed_ext ->
        send_resp(conn, 415, "Unsupported media type")

      File.regular?(requested) ->
        send_file(conn, 200, requested)

      true ->
        send_resp(conn, 404, "Not found")
    end
  end
end
