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
			# code format: HK17041234
			# @todo: check order code is unique
			num = rand(9999)
			self.code = "HK%.4d" % (created_at.strftime("%Y")[2..3]+created_at.strftime("%m")).to_s+num.to_s.rjust(4, '0')
			
			#lastest = FrontendOrder.where('extract(year from created_at) = ?', Time.now.year)
			#											.where('extract(month from created_at) = ?', Time.now.month)
			#											.order("code DESC").first
			#if !lastest.nil? && !lastest.code.nil?
			#	num = lastest.code[6..(-1)].to_i + 1
			#	self.code = "HK%.4d" % (created_at.strftime("%Y")[2..3]+created_at.strftime("%m")).to_s+num.to_s.rjust(4, '0')
			#else
			#	self.code = "HK%.4d" % (created_at.strftime("%Y")[2..3].to_s+created_at.strftime("%m")).to_s+1.to_s.rjust(4, '0')
			#end
		end
  end
end
