class AddConfirmedAtToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :confirmed_at, :datetime
  end
end
