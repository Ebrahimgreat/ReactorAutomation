defmodule GroceryApp.Suppliers.SupplierPrice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "supplier_prices" do
    field :price_per_unit, :decimal

    belongs_to :supplier, GroceryApp.Suppliers.Supplier
    belongs_to :product, GroceryApp.Inventory.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(supplier_price, attrs) do
    supplier_price
    |> cast(attrs, [:price_per_unit])
    |> validate_required([:price_per_unit])
  end
end
