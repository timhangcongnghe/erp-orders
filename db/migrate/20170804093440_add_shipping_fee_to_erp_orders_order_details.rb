class AddShippingFeeToErpOrdersOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_orders_order_details, :shipping_fee, :decimal
  end
end
