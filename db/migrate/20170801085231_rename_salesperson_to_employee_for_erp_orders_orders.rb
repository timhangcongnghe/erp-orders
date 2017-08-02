class RenameSalespersonToEmployeeForErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    rename_column :erp_orders_orders, :salesperson_id, :employee_id
  end
end
