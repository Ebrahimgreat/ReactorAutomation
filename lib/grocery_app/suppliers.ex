defmodule GroceryApp.Suppliers do
  @moduledoc """
  The Suppliers context.
  """

  import Ecto.Query, warn: false
  alias GroceryApp.Repo

  alias GroceryApp.Suppliers.Supplier

  @doc """
  Returns the list of suppliers.

  ## Examples

      iex> list_suppliers()
      [%Supplier{}, ...]

  """
  def list_suppliers do
    Repo.all(Supplier)
  end

  @doc """
  Gets a single supplier.

  Raises `Ecto.NoResultsError` if the Supplier does not exist.

  ## Examples

      iex> get_supplier!(123)
      %Supplier{}

      iex> get_supplier!(456)
      ** (Ecto.NoResultsError)

  """
  def get_supplier!(id), do: Repo.get!(Supplier, id)

  @doc """
  Creates a supplier.

  ## Examples

      iex> create_supplier(%{field: value})
      {:ok, %Supplier{}}

      iex> create_supplier(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_supplier(attrs) do
    %Supplier{}
    |> Supplier.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a supplier.

  ## Examples

      iex> update_supplier(supplier, %{field: new_value})
      {:ok, %Supplier{}}

      iex> update_supplier(supplier, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_supplier(%Supplier{} = supplier, attrs) do
    supplier
    |> Supplier.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a supplier.

  ## Examples

      iex> delete_supplier(supplier)
      {:ok, %Supplier{}}

      iex> delete_supplier(supplier)
      {:error, %Ecto.Changeset{}}

  """
  def delete_supplier(%Supplier{} = supplier) do
    Repo.delete(supplier)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking supplier changes.

  ## Examples

      iex> change_supplier(supplier)
      %Ecto.Changeset{data: %Supplier{}}

  """
  def change_supplier(%Supplier{} = supplier, attrs \\ %{}) do
    Supplier.changeset(supplier, attrs)
  end

  alias GroceryApp.Suppliers.SupplierPrice

  @doc """
  Returns the list of supplier_prices.

  ## Examples

      iex> list_supplier_prices()
      [%SupplierPrice{}, ...]

  """
  def list_supplier_prices do
    Repo.all(SupplierPrice)
  end

  @doc """
  Gets a single supplier_price.

  Raises `Ecto.NoResultsError` if the Supplier price does not exist.

  ## Examples

      iex> get_supplier_price!(123)
      %SupplierPrice{}

      iex> get_supplier_price!(456)
      ** (Ecto.NoResultsError)

  """
  def get_supplier_price!(id), do: Repo.get!(SupplierPrice, id)

  @doc """
  Creates a supplier_price.

  ## Examples

      iex> create_supplier_price(%{field: value})
      {:ok, %SupplierPrice{}}

      iex> create_supplier_price(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_supplier_price(attrs) do
    %SupplierPrice{}
    |> SupplierPrice.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a supplier_price.

  ## Examples

      iex> update_supplier_price(supplier_price, %{field: new_value})
      {:ok, %SupplierPrice{}}

      iex> update_supplier_price(supplier_price, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_supplier_price(%SupplierPrice{} = supplier_price, attrs) do
    supplier_price
    |> SupplierPrice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a supplier_price.

  ## Examples

      iex> delete_supplier_price(supplier_price)
      {:ok, %SupplierPrice{}}

      iex> delete_supplier_price(supplier_price)
      {:error, %Ecto.Changeset{}}

  """
  def delete_supplier_price(%SupplierPrice{} = supplier_price) do
    Repo.delete(supplier_price)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking supplier_price changes.

  ## Examples

      iex> change_supplier_price(supplier_price)
      %Ecto.Changeset{data: %SupplierPrice{}}

  """
  def change_supplier_price(%SupplierPrice{} = supplier_price, attrs \\ %{}) do
    SupplierPrice.changeset(supplier_price, attrs)
  end

  def find_by_name(name) do
    Repo.get_by(Supplier, name: name)
  end

  # Finding the Cheapest Supplier
  def find_cheapest(product_id) do
    from(sp in SupplierPrice,
      where: sp.product_id == ^product_id,
      order_by: [asc: sp.price_per_unit],
      limit: 1,
      preload: [:supplier]
    )
    |> Repo.one()
  end

  def list_products_with_prices(supplier_id) when is_binary(supplier_id),
    do: list_products_with_prices(String.to_integer(supplier_id))

  def list_products_with_prices(supplier_id) do
    from(sp in SupplierPrice,
      where: sp.supplier_id == ^supplier_id,
      join: p in GroceryApp.Inventory.Product,
      on: p.id == sp.product_id,
      select: %{id: p.id, name: p.name, unit: p.unit, price: sp.price_per_unit}
    )
    |> Repo.all()
    |> Enum.map(fn row -> %{row | price: Decimal.to_string(row.price)} end)
  end
end
