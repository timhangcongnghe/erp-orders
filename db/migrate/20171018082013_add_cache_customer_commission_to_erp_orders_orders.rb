class AddCacheCustomerCommissionToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :cache_customer_commission_amount, :decimal
  end
end
