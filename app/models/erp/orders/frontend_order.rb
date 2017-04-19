module Erp::Orders
  class FrontendOrder < ApplicationRecord
		validates :customer_id, :consignee_id, :presence => true
    if Erp::Core.available?("contacts")
			belongs_to :customer, class_name: "Erp::Contacts::Contact", foreign_key: :customer_id
			belongs_to :consignee, class_name: "Erp::Contacts::Contact", foreign_key: :consignee_id
    end
    
    has_many :frontend_order_details, dependent: :destroy
    
    #save cart
		def save_from_cart(cart)
			cart.cart_items.each do |item|
				self.frontend_order_details.create(product_id: item.product_id, quantity: item.quantity)
			end
		end
		
		# class const
		STATUS_NEW = 'new'
		
		# get data column
    def get_data
      JSON.parse(self.data)
    end
    
    # get customer from frontend_order data
    def get_customer_data(attr)
      get_data["customer"][attr]
    end
    
    # get consignee from frontend_order data
    def get_consignee_data(attr)
      get_data["consignee"][attr]
    end
    
    # display note
    def display_note
      note.gsub("\r\n", "<br/>").html_safe
    end
  end
end
