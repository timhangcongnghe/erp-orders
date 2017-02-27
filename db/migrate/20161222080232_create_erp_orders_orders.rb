class CreateErpOrdersOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :erp_orders_orders do |t|
      t.string :code
      t.datetime :order_date
      t.string :status
      t.string :cache_payment_status
      t.references :creator, index: true, references: :erp_users
      t.references :customer, index: true, references: :erp_contacts_contacts
      t.references :supplier, index: true, references: :erp_contacts_contacts
      t.references :warehouse, index: true, references: :erp_warehouses_warehouses
      t.references :salesperson, index: true, references: :erp_users

      t.timestamps
    end
  end
end
