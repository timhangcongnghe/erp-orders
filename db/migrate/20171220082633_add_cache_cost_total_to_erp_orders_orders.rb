class AddCacheCostTotalToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :cache_cost_total, :decimal, default: 0
  end
end
