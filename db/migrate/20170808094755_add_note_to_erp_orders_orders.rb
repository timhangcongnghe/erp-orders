class AddNoteToErpOrdersOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_orders, :note, :text
  end
end
