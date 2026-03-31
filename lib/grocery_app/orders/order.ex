defmodule GroceryApp.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :quantity, :integer
    field :total_price, :decimal
    field :status, :string

    belongs_to :product, GroceryApp.Inventory.Product
    belongs_to :supplier, GroceryApp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:quantity, :total_price, :status, :product_id, :supplier_id])
    |> validate_required([:quantity, :total_price, :status])
    |> assoc_constraint(:product)
    |> assoc_constraint(:supplier)
  end
end
