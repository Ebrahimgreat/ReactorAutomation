defmodule GroceryApp.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GroceryApp.Inventory` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        current_stock: 42,
        name: "some name",
        reorder_threshold: 42,
        unit: "some unit"
      })
      |> GroceryApp.Inventory.create_product()

    product
  end
end
