defmodule GroceryApp.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false
  alias GroceryApp.Repo

  alias GroceryApp.Inventory.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    from(p in Product, order_by: [asc: p.id])
    |> Repo.all()
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  def refresh_stock(product_id) do
    product = Repo.get!(Product, product_id)
    product
    |> Ecto.Changeset.change(current_stock: product.reorder_threshold * 2)
    |> Repo.update()
  end

  def restock_product(product_id) do
    product = Repo.get!(Product, product_id)
    product
    |> Ecto.Changeset.change(current_stock: product.reorder_threshold * 5)
    |> Repo.update()
  end

  def update_stock(product_id, amount) do
    product = Repo.get!(Product, product_id)
    new_stock = max(product.current_stock - amount, 0)
    product
    |> Ecto.Changeset.change(current_stock: new_stock)
    |> Repo.update()
  end

  def undo_restock(product_id) do
    product = Repo.get!(Product, product_id)
    product
    |> Ecto.Changeset.change(current_stock: product.reorder_threshold - 1)
    |> Repo.update()
  end


end
