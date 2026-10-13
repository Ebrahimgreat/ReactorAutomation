defmodule GroceryApp.SupplierAutomation do
  alias PlaywrightEx.{Browser, BrowserContext, Frame, Page}

  @timeout 10_000

  # Starting cursor position (top-left area of the viewport)
  @start_x 120
  @start_y 80

  @doc """
  Navigates to the supplier's local page, finds the product row,
  clicks "Add to Cart", and waits for the order confirmation.

  supplier_url  - e.g. "http://localhost:4000/suppliers/foodpanda/index.html"
  product_name  - e.g. "Milk" (case-insensitive match against data-product)
  """
  def run(supplier_url, product_name) do
    headless = Application.get_env(:grocery_app, :playwright_headless, true)

    with {:ok, browser} <-
           PlaywrightEx.launch_browser(:chromium,
             timeout: 30_000,
             headless: headless,
             args: ["--no-sandbox"]
           ),
         result <- do_run(browser, supplier_url, product_name) do
      Browser.close(browser.guid, timeout: 5_000)
      result
    end
  end

  defp do_run(browser, url, product_name) do
    product_key = String.downcase(product_name)

    with {:ok, context} <-
           Browser.new_context(browser.guid,
             timeout: @timeout,
             viewport: %{width: 1280, height: 800}
           ),
         {:ok, page} <- BrowserContext.new_page(context.guid, timeout: @timeout) do
      browse(page.guid, page.main_frame.guid, url, product_key)
    end
  end

  defp browse(pid, fid, url, product_key) do
    selector = "button.add-to-cart[data-product='#{product_key}']"

    with {:ok, _} <- Frame.goto(fid, url: url, timeout: @timeout),
         # Let the page visually settle before doing anything
         :ok <- human_pause(1_200, 2_000),
         {:ok, _} <-
           Frame.wait_for_selector(fid,
             selector: "#product-catalog",
             timeout: @timeout
           ),
         # Simulate reading/scanning the catalog
         :ok <- human_pause(800, 1_500),
         # Resolve the button's bounding box
         {:ok, box} <-
           Frame.evaluate(fid,
             expression:
               ~s[(function(){ var el = document.querySelector("#{selector}"); if (!el) return null; var r = el.getBoundingClientRect(); return { x: r.x, y: r.y, width: r.width, height: r.height }; })()],
             timeout: @timeout
           ),
         # Pick a natural click point within the button
         {:ok, {tx, ty}} <- random_point_in_box(box),
         # Smoothly glide the cursor from its starting position to the button
         :ok <- smooth_mouse_move(pid, @start_x, @start_y, tx, ty),
         # Brief hover dwell before pressing
         :ok <- human_pause(120, 300),
         {:ok, _} <- Page.mouse_down(pid, timeout: @timeout),
         :ok <- human_pause(60, 150),
         {:ok, _} <- Page.mouse_up(pid, timeout: @timeout),
         # Brief pause while the page processes the click
         :ok <- human_pause(600, 1_000),
         {:ok, _} <-
           Frame.wait_for_selector(fid,
             selector: "#order-confirmation",
             timeout: @timeout
           ) do
      {:ok, "Order placed on supplier site for #{product_key}"}
    end
  end

  # Moves the mouse from (x0, y0) to (x1, y1) in small steps with slight
  # random jitter on each step, mimicking a real hand moving across the screen.
  defp smooth_mouse_move(pid, x0, y0, x1, y1) do
    steps = 25
    # ms — gives ~450 ms total travel time
    delay_per_step = 18

    Enum.reduce_while(1..steps, :ok, fn i, :ok ->
      t = i / steps
      # Linear interpolation with small random jitter on intermediate points
      jitter = if i < steps, do: (:rand.uniform_real() - 0.5) * 6, else: 0.0
      mx = x0 + (x1 - x0) * t + jitter
      my = y0 + (y1 - y0) * t + jitter

      case Page.mouse_move(pid, x: mx, y: my, timeout: @timeout) do
        {:ok, _} ->
          Process.sleep(delay_per_step)
          {:cont, :ok}

        {:error, _} = err ->
          {:halt, err}
      end
    end)
  end

  # Returns a random {x, y} point within the element's bounding box,
  # biased toward the centre (avoids edges).
  defp random_point_in_box(%{"x" => x, "y" => y, "width" => w, "height" => h}) do
    margin_x = w * 0.2
    margin_y = h * 0.2
    cx = x + margin_x + :rand.uniform_real() * (w - margin_x * 2)
    cy = y + margin_y + :rand.uniform_real() * (h - margin_y * 2)
    {:ok, {cx, cy}}
  end

  defp random_point_in_box(nil), do: {:error, :element_not_found}

  # Sleeps for a random duration between min_ms and max_ms milliseconds.
  defp human_pause(min_ms, max_ms) do
    delay = min_ms + :rand.uniform(max_ms - min_ms)
    Process.sleep(delay)
    :ok
  end
end
