class AddPaymentForToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :payment_for, :string
  end
end
