defmodule GroceryApp.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GroceryApp.Orders` context.
  """

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        quantity: 42,
        status: "some status",
        total_price: "120.5"
      })
      |> GroceryApp.Orders.create_order()

    order
  end
end
