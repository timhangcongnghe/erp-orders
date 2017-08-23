class AddCacheTaxAmountToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :cache_tax_amount, :decimal
  end
end
