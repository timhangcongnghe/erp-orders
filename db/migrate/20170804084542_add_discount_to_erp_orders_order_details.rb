class AddDiscountToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :discount, :decimal
  end
end
