defmodule GroceryApp.Repo.Migrations.CreateSupplierPrices do
  use Ecto.Migration

  def change do
    create table(:supplier_prices) do
      add :price_per_unit, :decimal
      add :supplier_id, references(:suppliers, on_delete: :nothing)
      add :product_id, references(:products, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_prices, [:supplier_id])
    create index(:supplier_prices, [:product_id])
  end
end
