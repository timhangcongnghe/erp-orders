class RemoveWarehouseFromErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    remove_reference :erp_orders_orders, :warehouse, index: true, references: :erp_warehouses_warehouses
  end
end
