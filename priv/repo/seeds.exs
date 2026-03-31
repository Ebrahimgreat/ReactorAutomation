alias GroceryApp.Repo
alias GroceryApp.Inventory.Product
alias GroceryApp.Suppliers.Supplier
alias GroceryApp.Suppliers.SupplierPrice

# ── Products ──────────────────────────────────────────────
inserted_products = Enum.map([
  %Product{name: "Milk",   unit: "L",       reorder_threshold: 2,   current_stock: 5},
  %Product{name: "Eggs",   unit: "pieces",  reorder_threshold: 6,   current_stock: 12},
  %Product{name: "Bread",  unit: "pieces",  reorder_threshold: 1,   current_stock: 2},
  %Product{name: "Rice",   unit: "kg",      reorder_threshold: 1,   current_stock: 3},
  %Product{name: "Sugar",  unit: "kg",      reorder_threshold: 1,   current_stock: 2},
  %Product{name: "Oats",   unit: "g",       reorder_threshold: 200, current_stock: 800},
], &Repo.insert!/1)

# ── Suppliers ─────────────────────────────────────────────
naheed = Repo.insert!(%Supplier{
  name: "Naheed",
  website_url: "http://localhost:4000/suppliers/naheed/index.html",
  contact_email: "support@naheed.pk",

})

foodpanda = Repo.insert!(%Supplier{
  name: "Foodpanda",
  website_url: "http://localhost:4000/suppliers/foodpanda/index.html",
  contact_email: "support@foodpanda.pk"
})

ubereats = Repo.insert!(%Supplier{
  name: "Uber Eats",
  website_url: "http://localhost:4000/suppliers/ubereats/index.html",
  contact_email: "support@ubereats.pk",
})

# ── Prices ────────────────────────────────────────────────
# {product_index, naheed_price, foodpanda_price, ubereats_price}
price_data = [
  {0, "180.00", "175.00", "190.00"},  # Milk
  {1, "25.00",  "22.00",  "27.00"},   # Eggs
  {2, "120.00", "125.00", "118.00"},  # Bread
  {3, "350.00", "340.00", "360.00"},  # Rice
  {4, "160.00", "155.00", "165.00"},  # Sugar
  {5, "95.00",  "90.00",  "100.00"},  # Oats
]

Enum.each(price_data, fn {index, naheed_price, fp_price, ue_price} ->
  product = Enum.at(inserted_products, index)

  Repo.insert!(%SupplierPrice{supplier_id: naheed.id,    product_id: product.id, price_per_unit: Decimal.new(naheed_price)})
  Repo.insert!(%SupplierPrice{supplier_id: foodpanda.id, product_id: product.id, price_per_unit: Decimal.new(fp_price)})
  Repo.insert!(%SupplierPrice{supplier_id: ubereats.id,  product_id: product.id, price_per_unit: Decimal.new(ue_price)})
end)

IO.puts("✅ 3 suppliers seeded")
IO.puts("✅ #{length(inserted_products)} products seeded")
IO.puts("✅ #{length(price_data) * 3} supplier prices seeded")
