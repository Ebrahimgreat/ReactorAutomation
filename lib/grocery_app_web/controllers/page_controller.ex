defmodule GroceryAppWeb.PageController do
  use GroceryAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
