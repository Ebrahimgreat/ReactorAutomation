defmodule GroceryApp.SuppliersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GroceryApp.Suppliers` context.
  """

  @doc """
  Generate a supplier.
  """
  def supplier_fixture(attrs \\ %{}) do
    {:ok, supplier} =
      attrs
      |> Enum.into(%{
        contact_email: "some contact_email",
        name: "some name",
        website_url: "some website_url"
      })
      |> GroceryApp.Suppliers.create_supplier()

    supplier
  end

  @doc """
  Generate a supplier_price.
  """
  def supplier_price_fixture(attrs \\ %{}) do
    {:ok, supplier_price} =
      attrs
      |> Enum.into(%{
        price_per_unit: "120.5"
      })
      |> GroceryApp.Suppliers.create_supplier_price()

    supplier_price
  end
end
