class AddWarehouseIdToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :warehouse_id, :integer
  end
end
