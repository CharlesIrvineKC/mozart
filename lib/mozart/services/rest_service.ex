defmodule Mozart.Services.RestService do
  @moduledoc false
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://jsonplaceholder.typicode.com")
  plug(Tesla.Middleware.JSON)

  def call_json_api() do
    {:ok, response} = get("/todos/1")
    response.body
  end

end
