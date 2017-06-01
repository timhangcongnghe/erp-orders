class AddDescriptionToErpOrdersFrontendOrderDetails < ActiveRecord::Migration[5.0]
  def change
    add_column :erp_orders_frontend_order_details, :description, :text
  end
end
