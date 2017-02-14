# USER
user = Erp::User.first

puts "Create sample main contact"
Erp::Contacts::Contact.where(name: "HK Incotech").destroy_all
owner = Erp::Contacts::Contact.create(
  contact_type: Erp::Contacts::Contact::TYPE_COMPANY,
  name: "HK Incotech",
  code: "MC000#",
  address: "188 Numer 1 street, Go Vap district, HCM city",
  creator_id: user.id
)

# PRODUCTS
puts "Create sample categories"
Erp::Products::Category.where(name: "Main category").destroy_all
category1 = Erp::Products::Category.create(name: "Main category", creator_id: user.id)
Erp::Products::Category.where(name: "Secondary category").destroy_all
category2 = Erp::Products::Category.create(name: "Secondary category", creator_id: user.id)

puts "Create sample units"
Erp::Products::Unit.where(name: "Cái").destroy_all
unit1 = Erp::Products::Unit.create(name: "Cái", creator_id: user.id)
Erp::Products::Unit.where(name: "Hộp").destroy_all
unit2 = Erp::Products::Unit.create(name: "Hộp", creator_id: user.id)

puts "Create sample products"
Erp::Products::Product.where(code: 'P0001').destroy_all
product1 = Erp::Products::Product.create(
  code: 'P0001',
  name: 'Sweet Cake Love',
  category_id: category1.id,
  creator_id: user.id,
  price: 120000,
  cost: 950000,
  unit_id: unit1.id,
)
Erp::Products::Product.where(code: 'P0002').destroy_all
product2 = Erp::Products::Product.create(
  code: 'P0002',
  name: 'Dark Chocalate USA',
  category_id: category1.id,
  creator_id: user.id,
  price: 280000,
  cost: 200000,
  unit_id: unit2.id,
)
Erp::Products::Product.where(code: 'P0003').destroy_all
product3 = Erp::Products::Product.create(
  code: 'P0003',
  name: 'Bobby Bear - Small',
  category_id: category2.id,
  creator_id: user.id,
  price: 180000,
  cost: 130000,
  unit_id: unit1.id,
)
Erp::Products::Product.where(code: 'P0004').destroy_all
product4 = Erp::Products::Product.create(
  code: 'P0004',
  name: 'Toy - Small Train',
  category_id: category2.id,
  creator_id: user.id,
  price: 90000,
  cost: 60000,
  unit_id: unit1.id,
)



# CONTACTS
puts "Create sample supplier"
Erp::Contacts::Contact.where(name: "ABC Incotech").destroy_all
supplier1 = Erp::Contacts::Contact.create(
  contact_type: Erp::Contacts::Contact::TYPE_COMPANY,
  name: "ABC Incotech",
  code: "S0001",
  address: "188 Numer 1 street, Go Vap district, HCM city",
  creator_id: user.id
)
puts supplier1.errors.to_json if !supplier1.errors.empty?
puts "Create sample customer"
Erp::Contacts::Contact.where(name: "Jonh Carter").destroy_all
customer1 = Erp::Contacts::Contact.create(
  contact_type: Erp::Contacts::Contact::TYPE_PERSON,
  name: "Jonh Carter",
  code: "C0001",
  address: "Cecilia Chapman 711-2880 Nulla St.",
  creator_id: user.id
)
Erp::Contacts::Contact.where(name: "Marry Jane").destroy_all
customer2 = Erp::Contacts::Contact.create(
  contact_type: Erp::Contacts::Contact::TYPE_PERSON,
  name: "Marry Jane",
  code: "C0004",
  address: "122 Nulla St. Mankato Mississippi",
  creator_id: user.id
)

# WAREHOUSES
puts "Create sample warehouse"
Erp::Warehouses::Warehouse.where(name: "Main warehouse").destroy_all
warehouse = Erp::Warehouses::Warehouse.create(
  name: "Main warehouse",
  short_name: "Main Warehouse",
  creator_id: Erp::User.first.id,
  contact_id: owner.id
)
puts warehouse.errors.to_json if !warehouse.errors.empty?


# SALES ORDERS
puts "Create sample orders order"
Erp::Orders::Order.where(code: "O0001").destroy_all
orders_order1 = Erp::Orders::Order.create(
  supplier_id: owner.id,
  customer_id: customer1.id,
  code: "O0001",
  order_date: Time.now - 1.day,
  expiration_date: Time.now + 1.week,
  creator_id: user.id,
  salesperson_id: user.id,
  warehouse_id: warehouse.id
)
puts orders_order1.errors.to_json if !orders_order1.errors.empty?

puts "Create sample orders order detail"
order_detail1 = orders_order1.order_details.create(
  order_id: orders_order1.id,
  product_id: product1.id,
  unit_id: product1.unit.id,
  quantity: 3,
  price: product1.price,
  description: "With red colors"
)
puts order_detail1.errors.to_json if !order_detail1.errors.empty?
order_detail2 = orders_order1.order_details.create(
  order_id: orders_order1.id,
  product_id: product2.id,
  unit_id: product2.unit.id,
  quantity: 1,
  price: product2.price
)
puts order_detail2.errors.to_json if !order_detail2.errors.empty?

puts "Create sample sales order"
Erp::Orders::Order.where(code: "O0002").destroy_all
orders_order2 = Erp::Orders::Order.create(
  supplier_id: owner.id,
  customer_id: customer2.id,
  code: "O0002",
  order_date: Time.now,
  expiration_date: Time.now + 2.week,
  creator_id: user.id,
  salesperson_id: user.id,
  warehouse_id: warehouse.id
)
puts orders_order2.errors.to_json if !orders_order2.errors.empty?

puts "Create sample sales order detail"
order_detail3 = orders_order2.order_details.create(
  order_id: orders_order2.id,
  product_id: product3.id,
  unit_id: product3.unit.id,
  quantity: 3,
  price: product3.price
)
puts order_detail3.errors.to_json if !order_detail3.errors.empty?
order_detail4 = orders_order2.order_details.create(
  order_id: orders_order2.id,
  product_id: product1.id,
  unit_id: product1.unit.id,
  quantity: 1,
  price: product1.price
)
puts order_detail4.errors.to_json if !order_detail4.errors.empty?


# PURCHASE ORDERS
puts "Create sample purchase order"
Erp::Orders::Order.where(code: "PO0001").destroy_all
purchase_order1 = Erp::Orders::Order.create(
  supplier_id: supplier1.id,
  customer_id: owner.id,
  code: "PO0001",
  order_date: Time.now,
  expiration_date: Time.now + 2.week,
  creator_id: user.id,
  salesperson_id: user.id,
  warehouse_id: warehouse.id
)
puts purchase_order1.errors.to_json if !purchase_order1.errors.empty?

puts "Create sample purchase order detail"
order_detail1 = purchase_order1.order_details.create(
  order_id: purchase_order1.id,
  product_id: product1.id,
  unit_id: product1.unit.id,
  quantity: 10,
  price: product1.price,
  description: "With red colors"
)
puts order_detail1.errors.to_json if !order_detail1.errors.empty?
order_detail2 = purchase_order1.order_details.create(
  order_id: purchase_order1.id,
  product_id: product2.id,
  unit_id: product2.unit.id,
  quantity: 3,
  price: product2.price
)
puts order_detail2.errors.to_json if !order_detail2.errors.empty?

puts "Create sample purchase order"
Erp::Orders::Order.where(code: "PO0006").destroy_all
purchase_order2 = Erp::Orders::Order.create(
  supplier_id: supplier1.id,
  customer_id: owner.id,
  code: "PO0006",
  order_date: Time.now,
  expiration_date: Time.now + 2.week,
  creator_id: user.id,
  salesperson_id: user.id,
  warehouse_id: warehouse.id
)
puts purchase_order2.errors.to_json if !purchase_order2.errors.empty?

puts "Create sample purchase order detail"
order_detail3 = purchase_order2.order_details.create(
  order_id: purchase_order2.id,
  product_id: product3.id,
  unit_id: product3.unit.id,
  quantity: 15,
  price: product3.price
)
puts order_detail3.errors.to_json if !order_detail3.errors.empty?
order_detail4 = purchase_order2.order_details.create(
  order_id: purchase_order2.id,
  product_id: product4.id,
  unit_id: product4.unit.id,
  quantity: 2,
  price: product4.price
)
puts order_detail4.errors.to_json if !order_detail4.errors.empty?