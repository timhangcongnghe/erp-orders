class CreateErpOrdersFrontendOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :erp_orders_frontend_orders do |t|
      t.string :code
      t.string :status
      t.references :customer, index: true, references: :erp_contacts_contacts
      t.references :consignee, index: true, references: :erp_contacts_contacts
      t.text :data
      t.text :note

      t.timestamps
    end
  end
end