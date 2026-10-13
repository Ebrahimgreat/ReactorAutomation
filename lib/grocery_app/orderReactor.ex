defmodule GroceryApp.OrderWorkflow do
  use Reactor

  input(:product_id)
  input(:amount)
  input(:liveview_pid)

  step :fetch_product do
    argument(:product_id, input(:product_id))
    argument(:liveview_pid, input(:liveview_pid))

    run(fn %{product_id: product_id, liveview_pid: liveview_pid}, _context ->
      send(liveview_pid, {:step_progress, :fetch_product, "Fetching product details..."})

      case GroceryApp.Repo.get(GroceryApp.Inventory.Product, product_id) do
        nil -> {:error, "Product not found"}
        product -> {:ok, product}
      end
    end)
  end

  step :send_email do
    argument(:product, result(:fetch_product))
    argument(:amount, input(:amount))
    argument(:liveview_pid, input(:liveview_pid))

    run(fn %{product: product, amount: amount, liveview_pid: liveview_pid}, _context ->
      import Swoosh.Email

      send(
        liveview_pid,
        {:step_progress, :send_email, "Sending low stock alert for #{product.name}..."}
      )

      email =
        new()
        |> to("admin@example.com")
        |> from({"Grocery App", "noreply@grocery.app"})
        |> subject("Low stock alert: #{product.name}")
        |> text_body(
          "#{product.name} is running low — only #{amount} #{product.unit} remaining. Finding Best Supplier!"
        )

      case GroceryApp.Mailer.deliver(email) do
        {:ok, _} -> {:ok, "Email sent for #{product.name}"}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  step :find_cheapest_supplier do
    argument(:product_id, input(:product_id))
    argument(:liveview_pid, input(:liveview_pid))

    run(fn %{product_id: product_id, liveview_pid: liveview_pid}, _context ->
      send(
        liveview_pid,
        {:step_progress, :find_cheapest_supplier, "Searching for cheapest supplier..."}
      )

      case GroceryApp.Suppliers.find_cheapest(product_id) do
        nil ->
          {:error, "No supplier found for product"}

        supplier ->
          send(
            liveview_pid,
            {:step_progress, :find_cheapest_supplier,
             "Supplier chosen: #{supplier.supplier.name} at Rs. #{supplier.price_per_unit}"}
          )

          {:ok, supplier}
      end
    end)
  end

  step :place_order do
    argument(:product_id, input(:product_id))
    argument(:product, result(:fetch_product))
    argument(:supplier, result(:find_cheapest_supplier))
    argument(:liveview_pid, input(:liveview_pid))

    run(fn %{
             product_id: product_id,
             product: product,
             supplier: supplier,
             liveview_pid: liveview_pid
           },
           _context ->
      send(
        liveview_pid,
        {:step_progress, :place_order, "Opening #{supplier.supplier.name} website..."}
      )

      case GroceryApp.SupplierAutomation.run(supplier.supplier.website_url, product.name) do
        {:ok, _} ->
          send(
            liveview_pid,
            {:step_progress, :place_order,
             "Purchase confirmed on #{supplier.supplier.name}, recording order..."}
          )

          fake_order_id = "ORD-#{:rand.uniform(900_000) + 100_000}"

          case GroceryApp.Orders.create_order(%{
                 product_id: product_id,
                 supplier_id: supplier.supplier_id,
                 quantity: 1,
                 total_price: supplier.price_per_unit,
                 status: "placed"
               }) do
            {:ok, order} -> {:ok, %{order: order, order_id: fake_order_id}}
            {:error, changeset} -> {:error, changeset}
          end

        {:error, reason} ->
          {:error, "Playwright automation failed: #{inspect(reason)}"}
      end
    end)

    compensate(fn _reason, %{product_id: product_id}, _ ->
      GroceryApp.Orders.cancel_latest_order(product_id)
      :ok
    end)
  end

  step :restock_inventory do
    argument(:product_id, input(:product_id))
    argument(:liveview_pid, input(:liveview_pid))
    wait_for(:place_order)

    run(fn %{product_id: product_id, liveview_pid: liveview_pid}, _context ->
      send(liveview_pid, {:step_progress, :restock_inventory, "Restocking inventory..."})
      GroceryApp.Inventory.restock_product(product_id)
    end)

    compensate(fn _reason, %{product_id: product_id}, _ ->
      GroceryApp.Inventory.undo_restock(product_id)
      :ok
    end)
  end

  step :send_confirmation_email do
    argument(:product, result(:fetch_product))
    argument(:result, result(:place_order))
    argument(:supplier, result(:find_cheapest_supplier))
    argument(:liveview_pid, input(:liveview_pid))
    wait_for(:restock_inventory)

    run(fn %{product: product, result: result, supplier: supplier, liveview_pid: liveview_pid},
           _context ->
      import Swoosh.Email

      send(
        liveview_pid,
        {:step_progress, :send_confirmation_email, "Sending confirmation email..."}
      )

      email =
        new()
        |> to("admin@example.com")
        |> from({"Grocery Agent", "noreply@groceryagent.app"})
        |> subject("Order confirmed: #{product.name}")
        |> text_body("""
        Your order has been placed!

        Item:       #{product.name}
        Supplier:   #{supplier.supplier.name}
        Order ID:   #{result.order_id}
        Price:      Rs. #{supplier.price_per_unit}

        Stock has been updated.
        """)

      case GroceryApp.Mailer.deliver(email) do
        {:ok, _} ->
          message =
            "Order done! Supplier: #{supplier.supplier.name}, Order ID: #{result.order_id}"

          {:ok, %{message: message}}

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  return(:send_confirmation_email)
end
