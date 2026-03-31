defmodule GroceryAppWeb.SupplierProductController do
  use GroceryAppWeb, :controller

  def index(conn, %{"supplier_id" => supplier_id}) do
    products = GroceryApp.Suppliers.list_products_with_prices(supplier_id)
    json(conn, products)
  end

  def by_name(conn, %{"name" => name}) do
    case GroceryApp.Suppliers.find_by_name(name) do
      nil -> conn |> put_status(404) |> json(%{error: "Supplier not found"})
      supplier -> json(conn, GroceryApp.Suppliers.list_products_with_prices(supplier.id))
    end
  end
end
