module Erp::Orders
  class Order < ApplicationRecord
    belongs_to :creator, class_name: "Erp::User"
    belongs_to :employee, class_name: "Erp::User", foreign_key: :employee_id
    if Erp::Core.available?("contacts")
		belongs_to :customer, class_name: "Erp::Contacts::Contact", foreign_key: :customer_id
		belongs_to :supplier, class_name: "Erp::Contacts::Contact", foreign_key: :supplier_id
		end
    if Erp::Core.available?("warehouses")
			validates :warehouse_id, presence: true
			belongs_to :warehouse, class_name: "Erp::Warehouses::Warehouse", foreign_key: :warehouse_id
			
			# display warehouse name
			def warehouse_name
				warehouse.present? ? warehouse.name : ''
			end
		end
    if Erp::Core.available?("taxes")
			validates :tax_id, presence: true
			belongs_to :tax, class_name: "Erp::Taxes::Tax", foreign_key: :tax_id
			
			# tax name
			def tax_name
				if tax.present?
					tax.short_name.present? ? tax.short_name : tax.name
				end
			end
		end
    
    has_many :order_details, dependent: :destroy
    accepts_nested_attributes_for :order_details, :reject_if => lambda { |a| a[:product_id].blank? }, :allow_destroy => true
    
    if Erp::Core.available?("payments")
		has_many :payment_records, class_name: "Erp::Payments::PaymentRecord"
		has_many :debts, class_name: "Erp::Payments::Debt"
		end
    
    validates :code, uniqueness: true
    validates :customer_id, :supplier_id, :order_date, :employee_id, presence: true
    
    after_save :update_cache_payment_status
    after_save :update_cache_total
    after_save :update_tax_amount
    
    # class const
    TYPE_SALES_ORDER = 'sales'
    TYPE_PURCHASE_ORDER = 'purchase'
    
    STATUS_DRAFT = 'draft'
    STATUS_CONFIRMED = 'confirmed'
    STATUS_DELETED = 'deleted'
    STATUS_ACTIVE = [STATUS_CONFIRMED, STATUS_DELETED]
    if Erp::Core.available?("deliveries")
			after_save :update_cache_delivery_status
			has_many :deliveries, class_name: "Erp::Deliveries::Delivery"
			DELIVERY_STATUS_DELIVERED = 'delivered'
			DELIVERY_STATUS_NOT_DELIVERY = 'not_delivery'
			DELIVERY_STATUS_OVER_DELIVERED = 'over_delivered'
			
			def delivery_count
				deliveries.count
			end
			
			def delivery_count
				deliveries.count
			end
			
			def delivery_count
				deliveries.count
			end
			
			def delivered_deliveries
				deliveries.where(status: Erp::Deliveries::Delivery::DELIVERY_STATUS_DELIVERED)
			end
			
			def delivered_quantity
				count = 0
				delivered_deliveries.each do |d|
					count += d.delivery_details.sum(:quantity)
				end
				return count
			end
			
			def not_delivered_quantity
				items_count - delivered_quantity
			end
			
			def delivery_status
				remain = not_delivered_quantity
				if remain > 0
					return Erp::Orders::Order::DELIVERY_STATUS_NOT_DELIVERY
				elsif remain == 0
					return Erp::Orders::Order::DELIVERY_STATUS_DELIVERED
				else
					return Erp::Orders::Order::DELIVERY_STATUS_OVER_DELIVERED
				end
			end
			
			def update_cache_delivery_status
				self.update_column(:cache_delivery_status, self.delivery_status)
			end
			
		end    
    
    PAYMENT_STATUS_PAID = 'paid'
    PAYMENT_STATUS_OVERDUE = 'overdue'
    PAYMENT_STATUS_DEBT = 'debt'
    PAYMENT_STATUS_OVERPAID = 'overpaid'
    
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
				query = query.joins(:supplier)
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
    def total_amount
			return order_details.sum(&:total_amount)
		end
    
    def discount
			return order_details.sum(&:get_discount)
		end
    
    def shipping_fee
			return order_details.sum(&:get_shipping_fee)
		end
    
    # get total (after deducting related fees)
    def total
			return order_details.sum(&:total)
		end
    
    # tax count
    def taxx
			count = 0
			if tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_FIXED
				count = tax.amount
			elsif tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_PRICE
				count = (total_amount*(tax.amount))/100
			end
			return count
		end
    
    # items count
    def items_count
			order_details.sum(:quantity)
		end
    
    # Update cache total
    def update_cache_total
			self.update_column(:cache_total, self.total)
		end
    
    # Cache total
    def self.cache_total
			self.sum("erp_orders_orders.cache_total")
		end
    
    # update tax amount
    def update_tax_amount
			self.update_column(:tax_amount, self.taxx)
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
    
    def set_confirmed
      update_attributes(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end
    
    def set_deleted
      update_attributes(status: Erp::Orders::Order::STATUS_DELETED)
    end
    
    def self.set_confirmed_all
      update_all(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end
    
    def self.set_deleted_all
      update_all(status: Erp::Orders::Order::STATUS_DELETED)
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
				if status == Erp::Orders::Order::STATUS_DELETED
					total = 0.0
				else
					total = self.total
				end
				return total
			end
			
			# check if order is deleted
			def deleted?
				return self.status == Erp::Orders::Order::STATUS_DELETED
			end
			
			# set payment status
			def payment_status
				status = ''
				if self.status == Erp::Orders::Order::STATUS_CONFIRMED
					if remain_amount == 0
						status = Erp::Orders::Order::PAYMENT_STATUS_PAID
					elsif remain_amount > 0
						if Time.current < get_payment_deadline.end_of_day
							status = Erp::Orders::Order::PAYMENT_STATUS_DEBT
						else
							status = Erp::Orders::Order::PAYMENT_STATUS_OVERDUE
						end
					else
						status = Erp::Orders::Order::PAYMENT_STATUS_OVERPAID
					end
				elsif self.status == Erp::Orders::Order::STATUS_DELETED
					if remain_amount == 0
						status = ''
					else
						status = Erp::Orders::Order::PAYMENT_STATUS_OVERPAID
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
					self.order_date
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
    
    # Generate code
    after_save :generate_code
    def generate_code
			if !code.present?
				str = (sales? ? 'SO' : 'PO')
				update_columns(code: str + id.to_s.rjust(5, '0'))
			end
		end
  end
end
