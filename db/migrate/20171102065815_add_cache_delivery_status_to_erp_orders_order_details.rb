class AddCacheDeliveryStatusToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :cache_delivery_status, :string
  end
end
