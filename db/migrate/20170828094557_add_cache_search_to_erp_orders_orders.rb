class AddCacheSearchToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :cache_search, :text
  end
end
