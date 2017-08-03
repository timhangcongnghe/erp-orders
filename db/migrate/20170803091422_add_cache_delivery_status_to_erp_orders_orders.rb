class AddCacheDeliveryStatusToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :cache_delivery_status, :string
  end
end
