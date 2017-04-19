class CreateErpOrdersFrontendOrderDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :erp_orders_frontend_order_details do |t|
      t.references :product, index: true, references: :erp_products_products
      t.references :frontend_order, index: true, references: :erp_orders_frontend_orders
      t.string :product_name
      t.integer :quantity, default: 1
      t.decimal :price

      t.timestamps
    end
  end
end
