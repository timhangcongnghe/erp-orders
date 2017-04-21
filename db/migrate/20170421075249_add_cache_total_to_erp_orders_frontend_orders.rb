class AddCacheTotalToErpOrdersFrontendOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :erp_orders_frontend_orders, :cache_total, :string
  end
end
