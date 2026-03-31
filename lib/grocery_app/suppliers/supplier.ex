defmodule GroceryApp.Suppliers.Supplier do
  use Ecto.Schema
  import Ecto.Changeset

  schema "suppliers" do
    field :name, :string
    field :contact_email, :string
    field :website_url, :string

    has_many :supplier_prices, GroceryApp.Suppliers.SupplierPrice
    has_many :orders, GroceryApp.Orders.Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(supplier, attrs) do
    supplier
    |> cast(attrs, [:name, :contact_email, :website_url])
    |> validate_required([:name, :contact_email, :website_url])
  end
end
