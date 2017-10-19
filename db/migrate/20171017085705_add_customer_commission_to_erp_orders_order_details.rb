class AddCustomerCommissionToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :customer_commission, :decimal
  end
end
