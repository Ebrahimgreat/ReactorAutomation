defmodule GroceryApp.Repo do
  use Ecto.Repo,
    otp_app: :grocery_app,
    adapter: Ecto.Adapters.Postgres
end
