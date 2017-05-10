class AddCreatorIdToErpOrdersFrontendOrders < ActiveRecord::Migration[5.0]
  def change
    change_table :erp_orders_frontend_orders do |t|
      t.references :creator, index: true, references: :erp_users
    end
  end
end
