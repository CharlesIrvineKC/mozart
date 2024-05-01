defmodule Mozart.Services.RestService do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://cat-fact.herokuapp.com")
  plug(Tesla.Middleware.JSON)

  def get_cat_facts() do
    {:ok, response} = get("/facts")
    Enum.map(response.body, fn fact -> fact["text"] end)
  end
end
