class AddCacheRealRevenueToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :cache_real_revenue, :decimal
  end
end
