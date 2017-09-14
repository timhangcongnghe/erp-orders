# USER
users = Erp::User.all
owner = Erp::Contacts::Contact.get_main_contact
contacts = Erp::Contacts::Contact.where('id != ?', owner.id)
status = [Erp::Orders::Order::STATUS_DRAFT,
          Erp::Orders::Order::STATUS_CONFIRMED]
keys = ['SO', 'PO']
sale_taxes = Erp::Taxes::Tax.where(scope: Erp::Taxes::Tax::TAX_SCOPE_SALES)
purchase_taxes = Erp::Taxes::Tax.where(scope: Erp::Taxes::Tax::TAX_SCOPE_PURCHASES)

# Orders
Erp::Orders::Order.all.destroy_all
# Sales Orders
(1..30).each do |num|
  key = keys[rand(keys.count)]
  contact = contacts.order("RANDOM()").first
  order = Erp::Orders::Order.create(
    code: key + num.to_s.rjust(5, '0'),
    order_date: rand((Time.current - 5.day)..Time.current),
    supplier_id: (key==keys[0]) ? owner.id : contact.id,
    customer_id: (key==keys[0]) ? contact.id : owner.id,
    employee_id: users.order("RANDOM()").first.id,
    warehouse_id: Erp::Warehouses::Warehouse.order("RANDOM()").first.id,
    status: status[rand(status.count)],
    creator_id: users.order("RANDOM()").first.id,
    tax_id: (key==keys[0]) ? sale_taxes.sample.id : purchase_taxes.sample.id
  )
  
  if key == 'SO'
    rand_items = rand(3..8)
  else
    rand_items = rand(20..80)
  end
  Erp::Products::Product.where(id: Erp::Products::Product.pluck(:id).sample(rand_items)).each do |product|
    order_detail = Erp::Orders::OrderDetail.create(
      order_id: order.id,
      product_id: product.id,
      quantity: rand(1..2),
      price: product.get_price
    )
  end
  puts '==== Order ' +num.ordinalize+ ' complete ('+order.code+') ===='
end
