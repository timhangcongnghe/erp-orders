class AddCacheTotalToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :cache_total, :decimal
  end
end
