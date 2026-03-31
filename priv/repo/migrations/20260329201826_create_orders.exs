defmodule GroceryApp.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :quantity, :integer
      add :total_price, :decimal
      add :status, :string
      add :supplier_id, references(:suppliers, on_delete: :nothing)
      add :product_id, references(:products, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:supplier_id])
    create index(:orders, [:product_id])
  end
end
