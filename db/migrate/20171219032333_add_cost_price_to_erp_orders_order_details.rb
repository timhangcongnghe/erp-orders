class AddCostPriceToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :cost_price, :decimal, default: 0.0
  end
end
