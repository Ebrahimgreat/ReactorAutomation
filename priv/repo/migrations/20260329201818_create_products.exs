defmodule GroceryApp.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :unit, :string
      add :reorder_threshold, :integer
      add :current_stock, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
