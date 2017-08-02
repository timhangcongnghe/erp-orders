module Erp::Orders
  class Order < ApplicationRecord
    belongs_to :creator, class_name: "Erp::User"
    belongs_to :employee, class_name: "Erp::User", foreign_key: :employee_id
    if Erp::Core.available?("contacts")
			belongs_to :customer, class_name: "Erp::Contacts::Contact", foreign_key: :customer_id
			belongs_to :supplier, class_name: "Erp::Contacts::Contact", foreign_key: :supplier_id
		end
    has_many :order_details, dependent: :destroy
    accepts_nested_attributes_for :order_details, :reject_if => lambda { |a| a[:product_id].blank? }, :allow_destroy => true
    
    if Erp::Core.available?("payments")
			has_many :payment_records, class_name: "Erp::Payments::PaymentRecord"
			has_many :debts, class_name: "Erp::Payments::Debt"
		end
    
    after_save :update_cache_payment_status
    after_save :update_cache_total
    
    # class const
    STATUS_PAID = 'paid'
    STATUS_OVERDUE = 'overdue'
    STATUS_DEBT = 'debt'
    STATUS_RETURN_BACK = 'return_back'
    STATUS_DRAFT = 'draft'
    STATUS_CONFIRMED = 'confirmed'
    STATUS_CANCELLED = 'cancelled'
    STATUS_ACTIVE = [STATUS_CONFIRMED, STATUS_CANCELLED]
    
    TYPE_CUSTOMER_ORDER = 'sales'
    TYPE_PURCHASE_ORDER = 'purchase'
    
    # Filters
    def self.filter(query, params)
      params = params.to_unsafe_hash
      
      # join with users table for search creator
      query = query.joins(:creator)
      
      # join with users table for search employee
      query = query.joins(:employee)
      
      if Erp::Core.available?("contacts")
				# join with contacts table for search customer
				query = query.joins(:customer)
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
      if params[:date].present?
				date = params[:date].to_date
				query = query.where("order_date >= ? AND order_date <= ?", date.beginning_of_day, date.end_of_day)
			end
      
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
    
    # display employee
    def employee_name
			employee.present? ? employee.name : ''
		end
    
    # get total amount
    def total
			return order_details.sum('price * quantity')
		end
    
    # Update cache total
    def update_cache_total
			self.update_column(:cache_total, self.total)
		end
    
    # Cache total
    def self.cache_total
			self.sum("erp_orders_orders.cache_total")
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
    def self.sales_orders(from_date=nil, to_date=nil)
			query = self.where(supplier_id: Erp::Contacts::Contact.get_main_contact.id)
    
			if from_date.present?
        query = query.where("order_date >= ?", from_date.beginning_of_day)
      end
      
      if to_date.present?
        query = query.where("order_date <= ?", to_date.end_of_day)
      end
      
      return query
		end
    
    # Get all purchase orders
    def self.purchase_orders(from_date=nil, to_date=nil)
			query = self.where(customer_id: Erp::Contacts::Contact.get_main_contact.id)
			
			if from_date.present?
        query = query.where("order_date >= ?", from_date.beginning_of_day)
      end
      
      if to_date.present?
        query = query.where("order_date <= ?", to_date.end_of_day)
      end
      
      return query
		end
    
    # Get all active orders
    def self.all_confirmed
      self.where(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end
    
    def set_confirm
      update_attributes(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end
    
    def set_cancel
      update_attributes(status: Erp::Orders::Order::STATUS_CANCELLED)
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
					result = self.done_receiced_payment_records.sum(:amount) - self.done_paid_payment_records.sum(:amount)
				elsif self.purchase?
					result = - self.done_receiced_payment_records.sum(:amount) + self.done_paid_payment_records.sum(:amount)
				else
					return 0.0
				end
			end
			
			# get pay payment records for order
			def done_paid_payment_records
				self.payment_records.all_done.all_paid
			end
			
			# get receice payment records for order
			def done_receiced_payment_records
				self.payment_records.all_done.all_received
			end
			
			# get remain amount
			def remain_amount
				return self.ordered_amount - self.paid_amount
			end
			
			# ordered amount
			def ordered_amount
				if status == Erp::Orders::Order::STATUS_CANCELLED
					total = 0.0
				else
					total = self.total
				end
				return total
			end
			
			# check if order is cancelled
			def cancelled?
				return self.status == Erp::Orders::Order::STATUS_CANCELLED
			end
			
			# set payment status
			def payment_status
				status = ''
				if self.status == Erp::Orders::Order::STATUS_CONFIRMED
					if remain_amount == 0
						status = Erp::Orders::Order::STATUS_PAID
					elsif remain_amount > 0
						if Time.now < get_payment_deadline.end_of_day
							status = Erp::Orders::Order::STATUS_DEBT
						else
							status = Erp::Orders::Order::STATUS_OVERDUE
						end
					else
						status = Erp::Orders::Order::STATUS_RETURN_BACK
					end
				elsif self.status == Erp::Orders::Order::STATUS_CANCELLED
					if remain_amount == 0
						status = ''
					else
						status = Erp::Orders::Order::STATUS_RETURN_BACK
					end
				end
				
				return status
			end
			
			# update cache payment status
			def update_cache_payment_status
				self.update_columns(cache_payment_status: payment_status)
			end
			
			# get payment deadline
			def get_payment_deadline
				if !debts.empty?
					self.debts.last.deadline
				else
					Time.now
				end
			end
			
			# remain order quantity
			def remain_order_quantity
				total = 0
				order_details.each do |od|
					total += od.remain_quantity
				end
				return total
			end
		end
    
    if Erp::Core.available?("accounting")
			# Accounting: Orders need to payments
			def self.status_active_for_orders
				# @TODO
				self.where(status: Erp::Orders::Order::STATUS_ACTIVE)
			end
		end
    
    # count orders by date range
    def self.get_by_time(from_date, to_date)
			self.where("order_date >= ? AND order_date <= ?", from_date.beginning_of_day, to_date.end_of_day)
		end
  end
end
