defmodule GroceryAppWeb.GroceryLive do
  use GroceryAppWeb, :live_view

  alias GroceryApp.Inventory

  @workflow_steps [
    {:fetch_product, "Fetch Product"},
    {:send_email, "Alert Email"},
    {:find_cheapest_supplier, "Find Supplier"},
    {:place_order, "Place Order"},
    {:restock_inventory, "Restock"},
    {:send_confirmation_email, "Confirm"}
  ]

  def mount(_params, _session, socket) do
    products = Inventory.list_products()

    {:ok,
     assign(socket,
       products: products,
       alert: nil,
       order_status: nil,
       order_confirmation: nil,
       order_steps: [],
       active_step: nil,
       completed_steps: [],
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
            %{
              product_id: product_id,
              name: updated_product.name,
              amount: updated_product.current_stock,
              unit: updated_product.unit
            }
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
      result =
        Reactor.run(GroceryApp.OrderWorkflow, %{
          product_id: product_id,
          amount: product.current_stock,
          liveview_pid: liveview_pid
        })

      send(liveview_pid, {:order_result, product_id, result})
    end)

    {:noreply,
     assign(socket,
       alert: nil,
       order_status: :ordering,
       order_confirmation: nil,
       order_steps: [],
       active_step: nil,
       completed_steps: [],
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

    {:noreply,
     assign(socket,
       products: Inventory.list_products(),
       order_status: :done,
       order_confirmation: confirmation.message,
       active_step: nil,
       completed_steps: all_steps
     )}
  end

  def handle_info({:order_result, _product_id, {:error, reason}}, socket) do
    {:noreply,
     assign(socket, order_status: :error, order_error: inspect(reason), active_step: nil)}
  end

  defp step_state(step_key, active_step, completed_steps, order_status) do
    cond do
      order_status == :done -> :done
      step_key == active_step -> :active
      step_key in completed_steps -> :done
      true -> :pending
    end
  end

  defp stock_low?(product), do: product.current_stock <= product.reorder_threshold

  # Bar fills relative to twice the reorder point, so the threshold sits at the midpoint.
  defp stock_percent(%{reorder_threshold: t, current_stock: s}) when t > 0,
    do: min(round(s / (t * 2) * 100), 100)

  defp stock_percent(_), do: 100

  attr :state, :atom, required: true
  attr :label, :string, required: true
  attr :last, :boolean, default: false

  defp workflow_step(assigns) do
    ~H"""
    <li class="relative flex gap-3 pb-5 last:pb-0">
      <span
        :if={!@last}
        class={[
          "absolute left-[0.9rem] top-8 h-[calc(100%-2rem)] w-px",
          if(@state == :done, do: "bg-emerald-400", else: "bg-base-300")
        ]}
      />
      <span class={[
        "relative grid h-7 w-7 shrink-0 place-items-center rounded-full border text-xs transition-all duration-500",
        @state == :done && "border-emerald-500 bg-emerald-500 text-white",
        @state == :active && "border-sky-500 bg-sky-500/10 text-sky-600",
        @state == :pending && "border-base-300 bg-base-100 text-base-content/30"
      ]}>
        <%= case @state do %>
          <% :done -> %>
            <.icon name="hero-check-micro" class="h-4 w-4" />
          <% :active -> %>
            <span class="h-3 w-3 animate-spin rounded-full border-2 border-sky-500 border-t-transparent" />
          <% :pending -> %>
            <span class="h-1.5 w-1.5 rounded-full bg-current" />
        <% end %>
      </span>
      <span class={[
        "pt-1 text-sm transition-colors",
        @state == :pending && "text-base-content/40",
        @state == :active && "font-semibold text-sky-600",
        @state == :done && "text-base-content"
      ]}>
        {@label}
      </span>
    </li>
    """
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign(:workflow_steps, @workflow_steps)
      |> assign(:low_count, Enum.count(assigns.products, &stock_low?/1))

    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p class="text-xs font-semibold uppercase tracking-[0.25em] text-emerald-600">
            Inventory control
          </p>
          <h1 class="mt-2 text-3xl font-semibold tracking-tight">Grocery stock</h1>
          <p class="mt-2 max-w-xl text-sm leading-6 text-base-content/60">
            Track stock levels, consume items, and let the reorder workflow restock from the cheapest supplier.
          </p>
        </div>

        <div class="grid grid-cols-2 gap-3 sm:w-72">
          <div id="stat-tracked" class="rounded-2xl border border-base-300 bg-base-100 px-4 py-3">
            <p class="text-xs font-medium text-base-content/50">Tracked</p>
            <p class="mt-1 text-2xl font-semibold tabular-nums">{length(@products)}</p>
          </div>
          <div
            id="stat-low"
            class={[
              "rounded-2xl border px-4 py-3 transition-colors",
              if(@low_count > 0,
                do: "border-rose-300/60 bg-rose-500/5",
                else: "border-base-300 bg-base-100"
              )
            ]}
          >
            <p class="text-xs font-medium text-base-content/50">Low stock</p>
            <p class={[
              "mt-1 text-2xl font-semibold tabular-nums",
              @low_count > 0 && "text-rose-600"
            ]}>
              {@low_count}
            </p>
          </div>
        </div>
      </div>

      <div class="mt-8 grid gap-6 lg:grid-cols-3 lg:items-start">
        <section id="products" class="grid gap-4 sm:grid-cols-2 lg:col-span-2">
          <div
            :if={@products == []}
            class="rounded-2xl border border-dashed border-base-300 p-10 text-center text-sm text-base-content/50 sm:col-span-2"
          >
            No products yet.
          </div>

          <article
            :for={product <- @products}
            id={"product-#{product.id}"}
            class="group flex flex-col rounded-2xl border border-base-300 bg-base-100 p-5 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <h2 class="truncate text-base font-semibold capitalize">{product.name}</h2>
                <p class="mt-0.5 text-xs text-base-content/50">
                  Reorder at {product.reorder_threshold} {product.unit}
                </p>
              </div>
              <span class={[
                "inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold",
                if(stock_low?(product),
                  do: "bg-rose-500/10 text-rose-600",
                  else: "bg-emerald-500/10 text-emerald-600"
                )
              ]}>
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {if stock_low?(product), do: "Low", else: "Healthy"}
              </span>
            </div>

            <div class="mt-5 flex items-baseline gap-1.5">
              <span class="text-3xl font-semibold tabular-nums tracking-tight">
                {product.current_stock}
              </span>
              <span class="text-sm text-base-content/50">{product.unit}</span>
            </div>

            <div class="relative mt-3 h-2 overflow-hidden rounded-full bg-base-200">
              <div
                class={[
                  "h-full rounded-full transition-all duration-500",
                  if(stock_low?(product), do: "bg-rose-500", else: "bg-emerald-500")
                ]}
                style={"width: #{stock_percent(product)}%"}
              />
              <span class="absolute inset-y-0 left-1/2 w-px bg-base-content/25" title="Reorder point" />
            </div>

            <div class="mt-5 grid grid-cols-2 gap-2">
              <button
                id={"consume-#{product.id}"}
                phx-click="consume"
                phx-value-product_id={product.id}
                class="inline-flex items-center justify-center gap-1.5 rounded-xl border border-base-300 px-3 py-2 text-sm font-medium transition hover:border-amber-400 hover:bg-amber-500/10 hover:text-amber-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-400 active:scale-[0.98]"
              >
                <.icon name="hero-minus-circle" class="h-4 w-4 shrink-0" />
                <span class="truncate">Use {product.reorder_threshold}</span>
              </button>
              <button
                id={"refresh-#{product.id}"}
                phx-click="refresh_stock"
                phx-value-product_id={product.id}
                class="inline-flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500/10 px-3 py-2 text-sm font-medium text-emerald-700 transition hover:bg-emerald-500/20 focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-400 active:scale-[0.98]"
              >
                <.icon name="hero-arrow-path" class="h-4 w-4 shrink-0" />
                <span>Refresh</span>
              </button>
            </div>
          </article>
        </section>

        <aside class="flex flex-col gap-4 lg:sticky lg:top-24">
          <div
            :if={@alert}
            id="low-stock-alert"
            class="rounded-2xl border border-rose-300/60 bg-rose-500/5 p-5"
          >
            <div class="flex gap-3">
              <span class="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-rose-500/15 text-rose-600">
                <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
              </span>
              <div>
                <p class="font-semibold capitalize">{@alert.name} is running low</p>
                <p class="mt-0.5 text-sm text-base-content/60">
                  {@alert.amount} {@alert.unit} remaining. Reorder from the cheapest supplier?
                </p>
              </div>
            </div>
            <div class="mt-4 flex gap-2">
              <button
                id="reorder-button"
                phx-click="order"
                phx-value-product_id={@alert.product_id}
                class="flex-1 rounded-xl bg-rose-600 px-3 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-rose-700 active:scale-[0.98]"
              >
                Reorder now
              </button>
              <button
                id="dismiss-button"
                phx-click="dismiss"
                class="rounded-xl px-3 py-2 text-sm font-medium text-base-content/60 transition hover:bg-base-200 hover:text-base-content"
              >
                Not now
              </button>
            </div>
          </div>

          <div
            :if={@order_status}
            id="order-workflow"
            class="rounded-2xl border border-base-300 bg-base-100 p-5 shadow-sm"
          >
            <div class="flex items-center justify-between">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-base-content/50">
                Reorder workflow
              </p>
              <span class={[
                "rounded-full px-2.5 py-1 text-xs font-semibold",
                @order_status == :ordering && "bg-sky-500/10 text-sky-600",
                @order_status == :done && "bg-emerald-500/10 text-emerald-600",
                @order_status == :error && "bg-rose-500/10 text-rose-600"
              ]}>
                <%= case @order_status do %>
                  <% :ordering -> %>
                    In progress
                  <% :done -> %>
                    Complete
                  <% :error -> %>
                    Failed
                <% end %>
              </span>
            </div>

            <ol class="mt-5">
              <.workflow_step
                :for={{{key, label}, idx} <- Enum.with_index(@workflow_steps)}
                state={step_state(key, @active_step, @completed_steps, @order_status)}
                label={label}
                last={idx == length(@workflow_steps) - 1}
              />
            </ol>

            <ul
              :if={@order_steps != []}
              class="mt-5 space-y-1.5 border-t border-base-300 pt-4 text-xs text-base-content/60"
            >
              <li :for={msg <- @order_steps} class="flex gap-2">
                <.icon name="hero-check-micro" class="mt-px h-3.5 w-3.5 shrink-0 text-emerald-500" />
                <span>{msg}</span>
              </li>
            </ul>

            <div
              :if={@order_status == :done}
              class="mt-4 rounded-xl bg-emerald-500/10 p-3 text-sm text-emerald-700"
            >
              <p class="font-semibold">Order placed</p>
              <p class="mt-0.5">{@order_confirmation}</p>
            </div>

            <div
              :if={@order_status == :error}
              class="mt-4 rounded-xl bg-rose-500/10 p-3 text-sm text-rose-700"
            >
              <p class="font-semibold">Order failed</p>
              <p
                :if={@order_error}
                class="mt-1 max-h-40 overflow-auto whitespace-pre-wrap break-all font-mono text-xs"
              >
                {@order_error}
              </p>
            </div>
          </div>

          <div
            :if={!@alert && !@order_status}
            class="rounded-2xl border border-dashed border-base-300 p-6 text-center"
          >
            <.icon name="hero-check-badge" class="mx-auto h-8 w-8 text-emerald-500" />
            <p class="mt-2 text-sm font-medium">Nothing needs attention</p>
            <p class="mt-1 text-xs text-base-content/50">
              Low-stock alerts and reorder progress will appear here.
            </p>
          </div>
        </aside>
      </div>
    </Layouts.app>
    """
  end
end
