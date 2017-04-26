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
		before_create :create_order_code
		after_save :update_cache_total
		
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
    
    # get total amount
    def total
			return frontend_order_details.sum('price * quantity')
		end
    
    # Update cache total
    def update_cache_total
			self.update_column(:cache_total, self.total)
		end
    
    # Cache total
    def self.cache_total
			self.sum("erp_orders_frontend_orders.cache_total")
		end
    
    def create_order_code
			lastest = FrontendOrder.all.order("id DESC").last
			num = lastest.id.to_i + 1
			if !lastest.nil?
				self.code = "SO%.3d" % (rand(1..999)).to_s+(num*4).to_s.rjust(5, '0')
			else
				self.code = "SO%.3d" % (rand(1..999)).to_s+(1*4).to_s.rjust(5, '0')
			end
		end
  end
end
