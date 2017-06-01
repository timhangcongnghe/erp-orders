module Erp::Orders
  class FrontendOrder < ApplicationRecord
		validates :customer_id, :consignee_id, :presence => true
		belongs_to :creator, class_name: "Erp::User"
    if Erp::Core.available?("contacts")
			belongs_to :customer, class_name: "Erp::Contacts::Contact", foreign_key: :customer_id
			belongs_to :consignee, class_name: "Erp::Contacts::Contact", foreign_key: :consignee_id
    end
    
    has_many :frontend_order_details, dependent: :destroy
    accepts_nested_attributes_for :frontend_order_details, :reject_if => lambda { |a| a[:product_id].blank? }, :allow_destroy => true
    
    #save cart
    def save_from_cart(cart)
			order_details = []
			
			cart.cart_items.each do |item|
				
				order_detail = (order_details.select {|o| o.product_id == item.product_id}).first
				if order_detail.nil?
					order_detail = self.frontend_order_details.new(product_id: item.product_id, quantity: item.quantity)
					order_details << order_detail
				else
					order_detail.quantity += item.quantity
				end
				
				# gifts
				item.product.products_gifts.each do |gift|
					order_detail = (order_details.select {|o| o.product_id == gift.gift_id}).first
					if order_detail.nil?
						order_detail = self.frontend_order_details.new(
								product_id: gift.gift_id,
								quantity: gift.total_quantity(item),
								price: gift.price,
								description: 'Quà tặng')
						order_details << order_detail
					else
						order_detail.quantity += gift.quantity
					end
				end
				
			end
			
			order_details.each(&:save)
		end
    
		before_create :generate_order_code
		after_save :update_cache_total
		
		# class const
		STATUS_DRAFT = 'draft'
		STATUS_CONFIRMED = 'confirmed'
		STATUS_FINISHED = 'finished'
		STATUS_CANCELLED = 'cancelled'
		STATUS_IS_ACTIVE = [STATUS_DRAFT, STATUS_CONFIRMED]
		
		# Filters
    def self.filter(query, params)
      params = params.to_unsafe_hash
      
      # join with users table for search creator
      query = query.joins(:creator)
      
      if Erp::Core.available?("contacts")
				# join with contacts table for search customer
				query = query.joins(:customer)
				query = query.joins(:consignee)
			end
      
      and_conds = []
      
      #filters
      if params["filters"].present?
        params["filters"].each do |ft|
          or_conds = []
          ft[1].each do |cond|
            or_conds << "#{cond[1]["name"]} = '#{cond[1]["value"]}'"
          end
          and_conds << '('+or_conds.join(' OR ')+')' if !or_conds.empty?
        end
      end
      
      #keywords
      if params["keywords"].present?
        params["keywords"].each do |kw|
          or_conds = []
          kw[1].each do |cond|
            or_conds << "LOWER(#{cond[1]["name"]}) LIKE '%#{cond[1]["value"].downcase.strip}%'"
          end
          and_conds << '('+or_conds.join(' OR ')+')'
        end
      end
      
      # add conditions to query
      query = query.where(and_conds.join(' AND ')) if !and_conds.empty?
      
      # search by a date
#      if params[:date].present?
#				date = params[:date].to_date
#				query = query.where("order_date >= ? AND order_date <= ?", date.beginning_of_day, date.end_of_day)
#			end
      
      return query
    end
    
    def self.search(params)
      query = self.order("created_at DESC")
      query = self.filter(query, params)
      
      return query
    end		
		
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
    
    # Generates a random string from a set of easily readable characters
		def generate_order_code
			size = 4
			charset = %w{0 1 2 3 4 6 7 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z}
			self.code = "DH" + Time.now.strftime("%Y").last(2) + (0...size).map{ charset.to_a[rand(charset.size)] }.join
		end
    
    def set_confirm
      update_attributes(status: Erp::Orders::FrontendOrder::STATUS_CONFIRMED)
    end
    
    def set_finish
      update_attributes(status: Erp::Orders::FrontendOrder::STATUS_FINISHED)
    end
    
    def set_cancel
      update_attributes(status: Erp::Orders::FrontendOrder::STATUS_CANCELLED)
    end
    
    def self.set_confirm_all
      update_all(status: Erp::Orders::FrontendOrder::STATUS_CONFIRMED)
    end
    
    def self.set_finish_all
      update_all(status: Erp::Orders::FrontendOrder::STATUS_FINISHED)
    end
    
    def self.set_cancel_all
      update_all(status: Erp::Orders::FrontendOrder::STATUS_CANCELLED)
    end
    
    # check if order is cancelled
		def confirmed?
			return self.status == Erp::Orders::FrontendOrder::STATUS_CONFIRMED
		end
    
    # check if order is finished
		def finished?
			return self.status == Erp::Orders::FrontendOrder::STATUS_FINISHED
		end
    
    # check if order is cancelled
		def cancelled?
			return self.status == Erp::Orders::FrontendOrder::STATUS_CANCELLED
		end
  end
end
