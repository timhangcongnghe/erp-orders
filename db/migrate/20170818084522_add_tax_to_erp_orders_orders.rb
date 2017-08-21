class AddTaxToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :tax_amount, :decimal
    add_reference :erp_orders_orders, :tax, index: true, references: :erp_taxes_taxes
  end
end
