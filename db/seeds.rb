# USER
users = Erp::User.all
owner = Erp::Contacts::Contact.get_main_contact
contacts = Erp::Contacts::Contact.where('id != ?', owner.id)
status = [Erp::Orders::Order::STATUS_DRAFT,
          Erp::Orders::Order::STATUS_CONFIRMED]
keys = ['SO', 'PO']

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
    status: status[rand(status.count)],
    creator_id: users.order("RANDOM()").first.id
  )
  Erp::Products::Product.where(id: Erp::Products::Product.pluck(:id).sample(rand(20..80))).each do |product|
    order_detail = Erp::Orders::OrderDetail.create(
      order_id: order.id,
      product_id: product.id,
      quantity: rand(1..2),
      price: product.get_price
    )
  end
end
