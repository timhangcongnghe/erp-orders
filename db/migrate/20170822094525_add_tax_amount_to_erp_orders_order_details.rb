class AddTaxAmountToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :tax_amount, :decimal
  end
end
