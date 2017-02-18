module Erp::Orders
  class Order < ApplicationRecord
    belongs_to :creator, class_name: "Erp::User"
    belongs_to :salesperson, class_name: "Erp::User", foreign_key: :salesperson_id, optional: true
    if Erp::Core.available?("contacts")
			belongs_to :customer, class_name: "Erp::Contacts::Contact", foreign_key: :customer_id, optional: true
			belongs_to :supplier, class_name: "Erp::Contacts::Contact", foreign_key: :supplier_id, optional: true
		end
    if Erp::Core.available?("warehouses")
			belongs_to :warehouse, class_name: "Erp::Warehouses::Warehouse", foreign_key: :warehouse_id, optional: true
		end
    has_many :order_details, dependent: :destroy
    accepts_nested_attributes_for :order_details, :reject_if => lambda { |a| a[:product_id].blank? }, :allow_destroy => true
    
    if Erp::Core.available?("payments")
			has_many :payment_records, class_name: "Erp::Payments::PaymentRecord"
			has_many :debts, class_name: "Erp::Payments::Debt"
		end
    
    after_save :update_cache_payment_status
    
    # class const
    STATUS_PAID = 'paid'
    STATUS_NOT_PAID = 'not_paid'
    STATUS_DEBT = 'debt'
    STATUS_DRAFT = 'draft'
    STATUS_ITEMS_CONFIRMED = 'items_confirmed'
    STATUS_PRICE_CONFIRMED = 'price_confirmed'
    STATUS_CONFIRMED = 'confirmed'
    STATUS_CANCELLED = 'cancelled'
    
    # Filters
    def self.filter(query, params)
      params = params.to_unsafe_hash
      
      and_conds = []
      # show archived items condition - default: false
      show_archived = false
      
      #filters
      if params["filters"].present?
        params["filters"].each do |ft|
          or_conds = []
          ft[1].each do |cond|
            # in case filter is show archived
            if cond[1]["name"] == 'show_archived'
              # show archived items
              show_archived = true
            else
              or_conds << "#{cond[1]["name"]} = '#{cond[1]["value"]}'"
            end
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
      
      # join with users table for search creator
      query = query.joins(:creator)
      
      # showing archived items if show_archived is not true
      query = query.where(archived: false) if show_archived == false
      
      # join with users table for search salesperson
      query = query.joins(:salesperson)
      
      if Erp::Core.available?("contacts")
				# join with contacts table for search customer
				query = query.joins(:customer)
			end
      
      if Erp::Core.available?("warehouses")
				# join with warehouses table for search warehouse
				query = query.joins(:warehouse)
			end
			
			# add conditions to query
      query = query.where(and_conds.join(' AND ')) if !and_conds.empty?
      
      return query
    end
    
    def self.search(params)
      query = self.order("created_at DESC")
      query = self.filter(query, params)
      
      return query
    end
    
    # data for dataselect ajax
    def self.dataselect(keyword='')
      query = self.all
      
      if keyword.present?
        keyword = keyword.strip.downcase
        query = query.where('LOWER(id) LIKE ?', "%#{keyword}%", "%#{keyword}%")
      end
      
      query = query.limit(8).map{|order| {value: order.id, text: order.id} }
    end
    
    if Erp::Core.available?("contacts")
			# display customer
			def customer_name
				customer.present? ? customer.name : ''
			end
			
			# display supplier
			def supplier_name
				supplier.present? ? supplier.name : ''
			end
		end
    
    # display salesperson
    def salesperson_name
			salesperson.present? ? salesperson.name : ''
		end
    
    if Erp::Core.available?("warehouses")
			# display warehouse
			def warehouse_name
				warehouse.present? ? warehouse.warehouse_name : ''
			end
		end
    
    # get total amount
    def total
			return order_details.sum('price * quantity')
		end
    
    # check if order is sales order
    def sales?
			return self.supplier_id == Erp::Contacts::Contact.get_main_contact.id
		end
    
    # check if order is purchase order
    def purchase?
			return self.customer_id == Erp::Contacts::Contact.get_main_contact.id
		end
    
    # Get all sales orders
    def self.sales_orders
			return self.where(supplier_id: Erp::Contacts::Contact.get_main_contact.id)
		end
    
    # Get all purchase orders
    def self.purchase_orders
			return self.where(customer_id: Erp::Contacts::Contact.get_main_contact.id)
		end
    
    def archive
			update_columns(archived: true)
		end
		
		def unarchive
			update_columns(archived: false)
		end
    
    def self.archive_all
			update_all(archived: true)
		end
    
    def self.unarchive_all
			update_all(archived: false)
		end
    
    def set_draft
      update_columns(status: Erp::Orders::Order::STATUS_DRAFT)
    end
    
    def set_items_confirm
      update_columns(status: Erp::Orders::Order::STATUS_ITEMS_CONFIRMED)
    end
    
    def set_price_confirm
      update_columns(status: Erp::Orders::Order::STATUS_PRICE_CONFIRMED)
    end
    
    def set_confirm
      update_columns(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end
    
    def set_cancel
      update_columns(status: Erp::Orders::Order::STATUS_CANCELLED)
    end
    
    def self.set_draft_all
      update_all(status: Erp::Orders::Order::STATUS_DRAFT)
    end
    
    def self.set_items_confirm_all
      update_all(status: Erp::Orders::Order::STATUS_ITEMS_CONFIRMED)
    end
    
    def self.set_price_confirm_all
      update_all(status: Erp::Orders::Order::STATUS_PRICE_CONFIRMED)
    end
    
    def self.set_confirm_all
      update_all(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end
    
    def self.set_cancel_all
      update_all(status: Erp::Orders::Order::STATUS_CANCELLED)
    end
    
    if Erp::Core.available?("payments")
			# get paid amount for order
			def paid_amount
				if self.sales?
					result = self.receice_payment_records.sum(:amount) - self.pay_payment_records.sum(:amount)
				elsif self.purchase?
					result = - self.receice_payment_records.sum(:amount) + self.pay_payment_records.sum(:amount)
				end
				return 0.0
			end
			
			# get pay payment records for order
			def pay_payment_records
				self.payment_records.where(payment_type: Erp::Payments::PaymentRecord::PAYMENT_TYPE_PAY)
			end
			
			# get receice payment records for order
			def receice_payment_records
				self.payment_records.where(payment_type: Erp::Payments::PaymentRecord::PAYMENT_TYPE_RECEIVE)
			end
			
			# get remain amount
			def remain_amount
				return self.total - self.paid_amount
			end
			
			# update cache payment status
			def update_cache_payment_status
				if remain_amount == 0
					status = Erp::Orders::Order::STATUS_PAID
				else remain_amount > 0
					if Time.now > get_payment_deadline.end_of_day
						status = Erp::Orders::Order::STATUS_NOT_PAID
					else
						status = Erp::Orders::Order::STATUS_DEBT
					end
				end
				
				self.update_columns(cache_payment_status: status)
			end
			
			# get payment deadline
			def get_payment_deadline
				# @todo
				if !debts.empty?
					self.debts.last.deadline
				else
					Time.now
				end
			end
			
			def remain_order_quantity
				total = 0
				order_details.each do |od|
					total += od.remain_quantity
				end
				return total
			end
		end
  end
end
