defmodule GroceryApp.SuppliersTest do
  use GroceryApp.DataCase

  alias GroceryApp.Suppliers

  describe "suppliers" do
    alias GroceryApp.Suppliers.Supplier

    import GroceryApp.SuppliersFixtures

    @invalid_attrs %{name: nil, contact_email: nil, website_url: nil}

    test "list_suppliers/0 returns all suppliers" do
      supplier = supplier_fixture()
      assert Suppliers.list_suppliers() == [supplier]
    end

    test "get_supplier!/1 returns the supplier with given id" do
      supplier = supplier_fixture()
      assert Suppliers.get_supplier!(supplier.id) == supplier
    end

    test "create_supplier/1 with valid data creates a supplier" do
      valid_attrs = %{
        name: "some name",
        contact_email: "some contact_email",
        website_url: "some website_url"
      }

      assert {:ok, %Supplier{} = supplier} = Suppliers.create_supplier(valid_attrs)
      assert supplier.name == "some name"
      assert supplier.contact_email == "some contact_email"
      assert supplier.website_url == "some website_url"
    end

    test "create_supplier/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Suppliers.create_supplier(@invalid_attrs)
    end

    test "update_supplier/2 with valid data updates the supplier" do
      supplier = supplier_fixture()

      update_attrs = %{
        name: "some updated name",
        contact_email: "some updated contact_email",
        website_url: "some updated website_url"
      }

      assert {:ok, %Supplier{} = supplier} = Suppliers.update_supplier(supplier, update_attrs)
      assert supplier.name == "some updated name"
      assert supplier.contact_email == "some updated contact_email"
      assert supplier.website_url == "some updated website_url"
    end

    test "update_supplier/2 with invalid data returns error changeset" do
      supplier = supplier_fixture()
      assert {:error, %Ecto.Changeset{}} = Suppliers.update_supplier(supplier, @invalid_attrs)
      assert supplier == Suppliers.get_supplier!(supplier.id)
    end

    test "delete_supplier/1 deletes the supplier" do
      supplier = supplier_fixture()
      assert {:ok, %Supplier{}} = Suppliers.delete_supplier(supplier)
      assert_raise Ecto.NoResultsError, fn -> Suppliers.get_supplier!(supplier.id) end
    end

    test "change_supplier/1 returns a supplier changeset" do
      supplier = supplier_fixture()
      assert %Ecto.Changeset{} = Suppliers.change_supplier(supplier)
    end
  end

  describe "supplier_prices" do
    alias GroceryApp.Suppliers.SupplierPrice

    import GroceryApp.SuppliersFixtures

    @invalid_attrs %{price_per_unit: nil}

    test "list_supplier_prices/0 returns all supplier_prices" do
      supplier_price = supplier_price_fixture()
      assert Suppliers.list_supplier_prices() == [supplier_price]
    end

    test "get_supplier_price!/1 returns the supplier_price with given id" do
      supplier_price = supplier_price_fixture()
      assert Suppliers.get_supplier_price!(supplier_price.id) == supplier_price
    end

    test "create_supplier_price/1 with valid data creates a supplier_price" do
      valid_attrs = %{price_per_unit: "120.5"}

      assert {:ok, %SupplierPrice{} = supplier_price} =
               Suppliers.create_supplier_price(valid_attrs)

      assert supplier_price.price_per_unit == Decimal.new("120.5")
    end

    test "create_supplier_price/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Suppliers.create_supplier_price(@invalid_attrs)
    end

    test "update_supplier_price/2 with valid data updates the supplier_price" do
      supplier_price = supplier_price_fixture()
      update_attrs = %{price_per_unit: "456.7"}

      assert {:ok, %SupplierPrice{} = supplier_price} =
               Suppliers.update_supplier_price(supplier_price, update_attrs)

      assert supplier_price.price_per_unit == Decimal.new("456.7")
    end

    test "update_supplier_price/2 with invalid data returns error changeset" do
      supplier_price = supplier_price_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Suppliers.update_supplier_price(supplier_price, @invalid_attrs)

      assert supplier_price == Suppliers.get_supplier_price!(supplier_price.id)
    end

    test "delete_supplier_price/1 deletes the supplier_price" do
      supplier_price = supplier_price_fixture()
      assert {:ok, %SupplierPrice{}} = Suppliers.delete_supplier_price(supplier_price)
      assert_raise Ecto.NoResultsError, fn -> Suppliers.get_supplier_price!(supplier_price.id) end
    end

    test "change_supplier_price/1 returns a supplier_price changeset" do
      supplier_price = supplier_price_fixture()
      assert %Ecto.Changeset{} = Suppliers.change_supplier_price(supplier_price)
    end
  end
end
