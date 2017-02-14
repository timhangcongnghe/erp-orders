class CreateErpOrdersOrderDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :erp_orders_order_details do |t|
      t.references :product, index: true, references: :erp_products_products
      t.references :unit, index: true, references: :erp_products_units
      t.references :order, index: true, references: :erp_orders_orders
      t.integer :quantity, default: 1.0
      t.decimal :price
      t.text :description

      t.timestamps
    end
  end
end
