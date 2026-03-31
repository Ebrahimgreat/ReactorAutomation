# Grocery App

An automated grocery inventory management system built with Elixir, Phoenix LiveView, and Playwright browser automation.

## What it does

The app monitors product stock levels in real time. When a product drops to or below its reorder threshold, the system automatically:

1. Sends a low-stock alert email
2. Queries all suppliers and selects the cheapest one for that product
3. Uses Playwright to navigate the supplier's storefront and place an order
4. Restocks the inventory in the database
5. Sends an order confirmation email

All workflow steps are tracked in real time in the UI using Phoenix LiveView.

## Tech stack

- **Elixir / Phoenix 1.8** — backend and web framework
- **Phoenix LiveView** — real-time reactive UI without writing JavaScript
- **Ecto + PostgreSQL** — data persistence
- **Reactor** — saga/workflow orchestration with compensation (rollback) support
- **PlaywrightEx** — Chromium browser automation for placing supplier orders
- **Swoosh** — email delivery
- **Tailwind CSS v4** — styling

## Architecture

```
GroceryApp.OrderWorkflow (Reactor saga)
  ├── fetch_product        — load product from DB
  ├── send_email           — low-stock alert email
  ├── find_cheapest_supplier — query supplier_prices, pick lowest price
  ├── place_order          — Playwright automation → insert Order record
  ├── restock_inventory    — update current_stock in DB
  └── send_confirmation_email — order confirmation email
```

Each step sends a progress message to the LiveView PID for live UI updates. If any step fails, Reactor runs compensating actions to roll back the order and inventory changes.

## Supplier mock storefronts

The project includes local HTML mock storefronts for testing the Playwright automation without hitting real websites. They are served as static files and fetch product data from the app's own JSON API.

- `priv/static/suppliers/naheed/index.html`
- `priv/static/suppliers/foodpanda/index.html`

## Setup

### Prerequisites

- Elixir 1.15+
- PostgreSQL
- Node.js (for Playwright and asset building)

### Install and run

```bash
mix setup
```

This installs dependencies, sets up the database, and runs seeds (6 products, 3 suppliers, 18 supplier prices).

Install Playwright's Chromium browser:

```bash
cd assets && npx playwright install chromium && cd ..
```

Start the server:

```bash
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000).

### Environment variables (production)

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection URL |
| `SECRET_KEY_BASE` | Phoenix secret key (generate with `mix phx.gen.secret`) |
| `PHX_HOST` | Public hostname |
| `PORT` | HTTP port (default 4000) |

## Email configuration

Emails are sent to `admin@example.com` by default. Update the recipient addresses in `lib/grocery_app/orderReactor.ex` for your environment. In development, Swoosh's local adapter is used — you can view sent emails at [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox).

## Running tests

```bash
mix test
```
