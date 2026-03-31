defmodule GroceryApp.Inventory.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :unit, :string
    field :reorder_threshold, :integer
    field :current_stock, :integer

    has_many :supplier_prices, GroceryApp.Suppliers.SupplierPrice
    has_many :orders, GroceryApp.Orders.Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :unit, :reorder_threshold, :current_stock])
    |> validate_required([:name, :unit, :reorder_threshold, :current_stock])
  end
end
