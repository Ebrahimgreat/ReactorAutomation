defmodule GroceryAppWeb.GroceryLive do
  use GroceryAppWeb, :live_view

  alias GroceryApp.Inventory

  @workflow_steps [
    {:fetch_product,          "Fetch Product"},
    {:send_email,             "Alert Email"},
    {:find_cheapest_supplier, "Find Supplier"},
    {:place_order,            "Place Order"},
    {:restock_inventory,      "Restock"},
    {:send_confirmation_email,"Confirm"}
  ]

  def mount(_params, _session, socket) do
    products = Inventory.list_products()
    {:ok, assign(socket,
      products: products,
      alert: nil,
      order_status: nil,
      order_confirmation: nil,
      order_steps: [],
      active_step: nil,
      order_error: nil
    )}
  end

  def handle_event("consume", %{"product_id" => product_id}, socket) do
    product_id = String.to_integer(product_id)
    product = Inventory.get_product!(product_id)
    amount = product.reorder_threshold

    case Inventory.update_stock(product_id, amount) do
      {:ok, updated_product} ->
        alert =
          if updated_product.current_stock <= updated_product.reorder_threshold do
            %{product_id: product_id, name: updated_product.name, amount: updated_product.current_stock, unit: updated_product.unit}
          else
            nil
          end
        {:noreply, assign(socket, products: Inventory.list_products(), alert: alert)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("order", %{"product_id" => product_id}, socket) do
    product_id = String.to_integer(product_id)
    liveview_pid = self()

    product = Inventory.get_product!(product_id)

    Task.start(fn ->
      result = Reactor.run(GroceryApp.OrderWorkflow, %{
        product_id: product_id,
        amount: product.current_stock,
        liveview_pid: liveview_pid
      })
      send(liveview_pid, {:order_result, product_id, result})
    end)

    {:noreply, assign(socket,
      alert: nil,
      order_status: :ordering,
      order_confirmation: nil,
      order_steps: [],
      active_step: nil,
      order_error: nil
    )}
  end

  def handle_event("dismiss", _, socket) do
    {:noreply, assign(socket, alert: nil)}
  end

  def handle_event("refresh_stock", %{"product_id" => product_id}, socket) do
    product_id = String.to_integer(product_id)
    Inventory.refresh_stock(product_id)
    {:noreply, assign(socket, products: Inventory.list_products())}
  end

  def handle_info({:step_progress, step, message}, socket) do
    completed =
      Enum.take_while(@workflow_steps, fn {key, _} -> key != step end)
      |> Enum.map(fn {key, _} -> key end)

    steps = socket.assigns.order_steps ++ [message]
    {:noreply, assign(socket, order_steps: steps, active_step: step, completed_steps: completed)}
  end

  def handle_info({:order_result, _product_id, {:ok, confirmation}}, socket) do
    all_steps = Enum.map(@workflow_steps, fn {key, _} -> key end)
    {:noreply, assign(socket,
      products: Inventory.list_products(),
      order_status: :done,
      order_confirmation: confirmation.message,
      active_step: nil,
      completed_steps: all_steps
    )}
  end

  def handle_info({:order_result, _product_id, {:error, reason}}, socket) do
    {:noreply, assign(socket, order_status: :error, order_error: inspect(reason), active_step: nil)}
  end

  defp step_state(step_key, active_step, completed_steps, order_status) do
    cond do
      order_status == :done -> :done
      step_key == active_step -> :active
      step_key in (completed_steps || []) -> :done
      true -> :pending
    end
  end

  defp stock_low?(product), do: product.current_stock <= product.reorder_threshold

  defp consume_button_label(product), do: "Consume #{product.reorder_threshold} #{product.unit}"

  defp stock_badge_class(product) do
    if stock_low?(product) do
      "border-rose-200 bg-rose-50 text-rose-700"
    else
      "border-emerald-200 bg-emerald-50 text-emerald-700"
    end
  end

  defp action_button_class(:primary) do
    "inline-flex w-full items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-700 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-amber-300 hover:bg-amber-50 hover:text-amber-800 focus:outline-none focus:ring-2 focus:ring-amber-300"
  end

  defp action_button_class(:secondary) do
    "inline-flex w-full items-center justify-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm font-semibold text-emerald-700 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-emerald-300 hover:bg-emerald-100 focus:outline-none focus:ring-2 focus:ring-emerald-300"
  end

  def render(assigns) do
    assigns = assign(assigns, :workflow_steps, @workflow_steps)

    ~H"""
    <Layouts.app flash={@flash}>
      <section class="mb-6 overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-[0_24px_80px_-40px_rgba(15,23,42,0.35)]">
        <div class="border-b border-slate-200 bg-gradient-to-r from-amber-50 via-white to-emerald-50 px-6 py-5">
          <div class="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.32em] text-slate-500">Inventory Control</p>
              <h1 class="mt-2 text-2xl font-semibold tracking-tight text-slate-900">Automated Inventory System</h1>
              <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
                Keep stock levels current, consume items in one tap, and trigger supplier refreshes without letting the action bar break the layout.
              </p>
            </div>

            <div class="inline-flex items-center gap-2 self-start rounded-full border border-slate-200 bg-white/80 px-3 py-2 text-xs font-medium text-slate-600 shadow-sm backdrop-blur">
              <span class="h-2.5 w-2.5 rounded-full bg-emerald-500"></span>
              {@products |> Enum.count()} items tracked
            </div>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm text-slate-700">
            <thead class="bg-slate-50/80 text-xs uppercase tracking-[0.18em] text-slate-500">
            <tr>
              <th class="px-6 py-4 text-left font-semibold">Item</th>
              <th class="px-4 py-4 text-right font-semibold">Stock</th>
              <th class="px-4 py-4 text-right font-semibold">Unit</th>
              <th class="px-4 py-4 text-right font-semibold">Threshold</th>
              <th class="px-4 py-4 text-right font-semibold">Status</th>
              <th class="px-6 py-4 text-right font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for product <- @products do %>
              <tr class="border-t border-slate-200 transition-colors duration-200 hover:bg-slate-50/70">
                <td class="px-6 py-4">
                  <div class="flex flex-col gap-1">
                    <span class="text-sm font-semibold capitalize text-slate-900">{product.name}</span>
                    <span class="text-xs font-medium uppercase tracking-[0.2em] text-slate-400">
                      Reorder point at {product.reorder_threshold} {product.unit}
                    </span>
                  </div>
                </td>
                <td class="px-4 py-4 text-right font-mono text-[0.95rem] font-semibold text-slate-900">
                  {product.current_stock}
                </td>
                <td class="px-4 py-4 text-right text-slate-500">{product.unit}</td>
                <td class="px-4 py-4 text-right font-mono text-slate-500">{product.reorder_threshold}</td>
                <td class="px-4 py-4 text-right">
                  <%= if stock_low?(product) do %>
                    <span class={[
                      "inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold",
                      stock_badge_class(product)
                    ]}>
                      <span class="h-2 w-2 rounded-full bg-current opacity-80"></span>
                      Low stock
                    </span>
                  <% else %>
                    <span class={[
                      "inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold",
                      stock_badge_class(product)
                    ]}>
                      <span class="h-2 w-2 rounded-full bg-current opacity-80"></span>
                      Healthy
                    </span>
                  <% end %>
                </td>
                <td class="px-6 py-4">
                  <div class="ml-auto flex w-full min-w-[12rem] max-w-[16rem] flex-col gap-2 sm:w-auto sm:min-w-[14rem]">
                    <button
                      phx-click="consume"
                      phx-value-product_id={product.id}
                      class={action_button_class(:primary)}
                    >
                      <.icon name="hero-minus-circle" class="h-4 w-4 shrink-0" />
                      <span class="truncate">{consume_button_label(product)}</span>
                    </button>

                    <button
                      phx-click="refresh_stock"
                      phx-value-product_id={product.id}
                      class={action_button_class(:secondary)}
                    >
                      <.icon name="hero-arrow-path" class="h-4 w-4 shrink-0" />
                      <span>Refresh stock</span>
                    </button>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        </div>
      </section>

      <%= if @alert do %>
        <div class="mt-4 p-4 border border-red-500 rounded-lg bg-red-50 text-red-800">
          <p class="font-semibold">⚠️ {@alert.name} is low ({@alert.amount} {@alert.unit} remaining)</p>
          <div class="mt-3 flex gap-3">
            <%= cond do %>
              <% @order_status == :ordering -> %>
                <div class="flex items-center gap-2 text-blue-700 font-medium">
                  <span class="animate-spin inline-block w-4 h-4 border-2 border-blue-600 rounded-full border-t-transparent"></span>
                  Processing order...
                </div>
              <% true -> %>
                <button phx-click="order" phx-value-product_id={@alert.product_id} class="btn btn-sm btn-error">
                  Yes, reorder now
                </button>
                <button phx-click="dismiss" class="btn btn-sm btn-ghost">No thanks</button>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @order_status in [:ordering, :done] do %>
        <div class="mt-6">
          <p class="text-sm font-semibold text-base-content/60 mb-3 uppercase tracking-wide">Workflow</p>
          <div class="flex items-center gap-0 flex-wrap">
            <%= for {{step_key, label}, idx} <- Enum.with_index(@workflow_steps) do %>
              <%
                state = step_state(step_key, @active_step, Map.get(assigns, :completed_steps, []), @order_status)
                box_class = case state do
                  :done    -> "bg-green-100 border-green-500 text-green-800"
                  :active  -> "bg-blue-100 border-blue-500 text-blue-800 animate-pulse"
                  :pending -> "bg-base-200 border-base-300 text-base-content/40"
                end
                icon = case state do
                  :done    -> "✓"
                  :active  -> "⟳"
                  :pending -> "○"
                end
              %>
              <div class={"border rounded-lg px-3 py-2 text-xs font-medium text-center min-w-[90px] transition-all duration-700 #{box_class}"}>
                <div class="text-base leading-none mb-1">{icon}</div>
                <div>{label}</div>
              </div>
              <%= if idx < length(@workflow_steps) - 1 do %>
                <div class="text-base-content/30 px-1 text-lg font-light">→</div>
              <% end %>
            <% end %>
          </div>

          <%= if length(@order_steps) > 0 do %>
            <ul class="mt-4 space-y-1 text-sm text-base-content/70">
              <%= for {msg, i} <- Enum.with_index(@order_steps) do %>
                <li class="flex items-start gap-2">
                  <span class="text-green-500 mt-0.5">✓</span>
                  <span class={if i == length(@order_steps) - 1 and @order_status == :ordering, do: "font-medium text-blue-700", else: ""}>{msg}</span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      <% end %>

      <%= if @order_status == :done do %>
        <div class="mt-4 p-4 border border-green-500 rounded-lg bg-green-50 text-green-800">
          <p class="font-semibold">✅ Order placed!</p>
          <p class="mt-1 text-sm">{@order_confirmation}</p>
        </div>
      <% end %>

      <%= if @order_status == :error do %>
        <div class="mt-4 p-4 border border-yellow-500 rounded-lg bg-yellow-50 text-yellow-800">
          <p class="font-semibold">❌ Order failed.</p>
          <%= if @order_error do %>
            <p class="mt-1 text-sm font-mono">{@order_error}</p>
          <% end %>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
