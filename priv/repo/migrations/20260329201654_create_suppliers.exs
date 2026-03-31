defmodule GroceryApp.Repo.Migrations.CreateSuppliers do
  use Ecto.Migration

  def change do
    create table(:suppliers) do
      add :name, :string
      add :contact_email, :string
      add :website_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
