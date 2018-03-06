module Erp::Orders
  class Order < ApplicationRecord
    belongs_to :creator, class_name: "Erp::User"
    belongs_to :employee, class_name: "Erp::User", foreign_key: :employee_id
    if Erp::Core.available?("order_stock_checks")
		has_many :schecks, class_name: "Erp::OrderStockChecks::Scheck", dependent: :destroy
		end
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
			belongs_to :tax, class_name: "Erp::Taxes::Tax", foreign_key: :tax_id, optional: true

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


    after_save :update_cache_commission_amount
    after_save :update_cache_customer_commission_amount
    after_save :update_cache_tax_amount
    after_save :update_cache_total
    after_save :update_cache_payment_status

    # class const
    TYPE_SALES_ORDER = 'sales'
    TYPE_PURCHASE_ORDER = 'purchase'

    PAYMENT_FOR_ORDER = 'for_order'
    PAYMENT_FOR_CONTACT = 'for_contact'

    STATUS_DRAFT = 'draft'
    STATUS_STOCK_CHECKING = 'stock_checking'
    STATUS_STOCK_CHECKED = 'stock_checked'
    STATUS_STOCK_APPROVED = 'stock_approved'
    STATUS_CONFIRMED = 'confirmed'
    STATUS_DELETED = 'deleted'
    STATUS_ACTIVE = [STATUS_CONFIRMED, STATUS_DELETED]
    if Erp::Core.available?("qdeliveries")
			after_save :update_cache_delivery_status

			DELIVERY_STATUS_DELIVERED = 'delivered'
			DELIVERY_STATUS_NOT_DELIVERY = 'not_delivery'
			DELIVERY_STATUS_OVER_DELIVERED = 'over_delivered'

			def total_delivered_quantity
				count = 0
				order_details.each do |od|
					count += od.delivered_quantity
				end
				return count
			end

			def total_ordered_quantity
				order_details.sum(:quantity)
			end

			def not_delivered_quantity
				total_ordered_quantity - total_delivered_quantity
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

			def is_delivered?
				self.delivery_status == Order::DELIVERY_STATUS_DELIVERED
			end

			def update_cache_delivery_status
				self.update_column(:cache_delivery_status, self.delivery_status)
			end

		end

    PAYMENT_STATUS_PAID = 'paid'
    PAYMENT_STATUS_OVERDUE = 'overdue'
    PAYMENT_STATUS_DEBT = 'debt'
    PAYMENT_STATUS_OVERPAID = 'overpaid'

    def is_debt?
      self.payment_status == Order::PAYMENT_STATUS_DEBT
    end

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

      # filters
      if params["filters"].present?
        params["filters"].each do |ft|
          or_conds = []
          ft[1].each do |cond|
            or_conds << "#{cond[1]["name"]} = '#{cond[1]["value"]}'"
          end
          and_conds << '('+or_conds.join(' OR ')+')' if !or_conds.empty?
        end
      end

      # keywords
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

      # global filter
      global_filter = params[:global_filter]

      if global_filter.present?

        # if has period
        if global_filter[:period].present?
          period = Erp::Periods::Period.find(global_filter[:period])
          global_filter[:from_date] = period.from_date
          global_filter[:to_date] = period.to_date
        end

				# filter by order from date
				if global_filter[:from_date].present?
					query = query.where('order_date >= ?', global_filter[:from_date].to_date.beginning_of_day)
				end

				# filter by order to date
				if global_filter[:to_date].present?
					query = query.where('order_date <= ?', global_filter[:to_date].to_date.end_of_day)
				end

				# filter by order from date
				if global_filter[:order_from_date].present?
					query = query.where('order_date >= ?', global_filter[:order_from_date].to_date.beginning_of_day)
				end

				# filter by order to date
				if global_filter[:order_to_date].present?
					query = query.where('order_date <= ?', global_filter[:order_to_date].to_date.end_of_day)
				end

				# filter by order customer
				if global_filter[:customer].present?
					query = query.where(customer_id: global_filter[:customer])
				end

				# filter by order supplier
				if global_filter[:supplier].present?
					query = query.where(supplier_id: global_filter[:supplier])
				end

				# filter by order warehouse
				if global_filter[:warehouse].present?
					query = query.where(warehouse_id: global_filter[:warehouse])
				end

				# filter by doctor
				if global_filter[:doctor].present?
					query = query.where(doctor_id: global_filter[:doctor])
				end

				# filter by patient
				if global_filter[:patient].present?
					query = query.where(patient_id: global_filter[:patient])
				end

			end
      # end// global filter

      # single keyword
      if params[:keyword].present?
				keyword = params[:keyword].strip.downcase
				keyword.split(' ').each do |q|
					q = q.strip
					query = query.where('LOWER(erp_orders_orders.cache_search) LIKE ?', '%'+q+'%')
				end
			end

      return query
    end

    def self.search(params)
      query = self.all
      query = self.filter(query, params)

      # order
      if params[:sort_by].present?
        order = params[:sort_by]
        order += " #{params[:sort_direction]}" if params[:sort_direction].present?

        query = query.order(order)
      else
				query = query.order('created_at DESC')
      end

      return query
    end

    # data for dataselect ajax
    def self.dataselect(keyword='', params={})
			query = self.all

      if keyword.present?
        keyword = keyword.strip.downcase
        query = query.where('LOWER(code) LIKE ?', "%#{keyword}%")
      end

      # find order has product
      if params[:product_id].present?
				query = query.includes(:order_details).where(erp_orders_order_details: {product_id: params[:product_id]})
			end

      # orders by delivery type
      if params[:delivery_type].present?
				# only get confirmed order
				query = query.where(status: Order::STATUS_CONFIRMED)

				if [Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT].include?(params[:delivery_type])
					query = query.where(supplier_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
				end
				if [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT].include?(params[:delivery_type])
					query = query.where(customer_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
				end
			end

      # filter by status
      if params[:status].present?
				query = query.where(status: params[:status])
			end

      # filter by sales orders
      if params[:supplier_id].present?
				query = query.where(supplier_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
			end

      # filter by purchase orders
      if params[:customer_id].present?
				query = query.where(customer_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
			end

      # filter by payment_for
      if params[:payment_for].present?
				query = query.where(payment_for: params[:payment_for])
			end

      # customer id
      if params[:delivery].present? and params[:delivery][:customer_id].present?
				query = query.where(customer_id: params[:delivery][:customer_id])
			end

      # supplier id
      if params[:delivery].present? and params[:delivery][:supplier_id].present?
				query = query.where(supplier_id: params[:delivery][:supplier_id])
			end

      query = query.order("erp_orders_orders.order_date DESC").limit(8).map{|order| {value: order.id, text: order.get_name} }

      if params[:include_na].present?
				query = [{value: '-1', text: params[:include_na]}] + query
			end

			return query
    end

    if Erp::Core.available?("contacts")# display customer

			# display creator
			def creator_name
				creator.present? ? creator.name : ''
			end

			# display customer
			def customer_code
				customer.present? ? customer.code : ''
			end

			def customer_name
				customer.present? ? customer.name : ''
			end

			# display supplier
			def supplier_code
				supplier.present? ? supplier.code : ''
			end

			def supplier_name
				supplier.present? ? supplier.name : ''
			end
		end

    # display employee
    def employee_name
			employee.present? ? employee.name : ''
		end

    # items count
    def items_count
			order_details.sum(:quantity)
		end

    # get sub total amount
    def subtotal
			return order_details.sum(&:subtotal)
		end

    # get discount amount
    def discount_amount
			return order_details.sum(&:discount_amount)
		end

    # get shipping amount
    def commission_amount
			return order_details.sum(&:commission_amount)
		end

    # get customer commission amount
    def customer_commission_amount
			return order_details.sum(&:customer_commission_amount)
		end

    # get shipping amount
    def shipping_amount
			return order_details.sum(&:shipping_amount)
		end

    # get total without tax
    def total_without_tax
			return order_details.sum(&:total_without_tax)
    end
    # get tax amount
    def tax_amount
			return order_details.sum(&:tax_amount)
		end

    # get total
    def total
			return order_details.sum(&:total)
		end

    # get total without commission amount
    def total_without_customer_commission
      total - commission_amount
    end

    # Update cache commission
    def update_cache_commission_amount
			self.update_column(:cache_commission_amount, self.commission_amount)
		end

    # Update cache customer commission
    def update_cache_customer_commission_amount
			self.update_column(:cache_customer_commission_amount, self.customer_commission_amount)
		end

    # update tax amount
    def update_cache_tax_amount
			self.update_column(:cache_tax_amount, self.tax_amount)
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
			return self.supplier_id == Erp::Contacts::Contact::MAIN_CONTACT_ID
		end

    # check if order is purchase order
    def purchase?
			return self.customer_id == Erp::Contacts::Contact::MAIN_CONTACT_ID
		end

		# check if order is draft
		def is_draft?
			return self.status == Erp::Orders::Order::STATUS_DRAFT
		end

		# check if order is stock_checking
		def is_stock_checking?
			return self.status == Erp::Orders::Order::STATUS_STOCK_CHECKING
		end

		# check if order is stock_checked
		def is_stock_checked?
			return self.status == Erp::Orders::Order::STATUS_STOCK_CHECKED
		end

		# check if order is stock_approved
		def is_stock_approved?
			return self.status == Erp::Orders::Order::STATUS_STOCK_APPROVED
		end

		# check if order is deleted
		def is_confirmed?
			return self.status == Erp::Orders::Order::STATUS_CONFIRMED
		end

		# check if order is deleted
		def is_deleted?
			return self.status == Erp::Orders::Order::STATUS_DELETED
		end

    # Get all sales orders
    def self.sales_orders
			self.where(supplier_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
		end

    # Get all purchase orders
    def self.purchase_orders
			self.where(customer_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
		end

    # Get all orders (payment_for: 'for_order')
    def self.payment_for_order_orders(params={})
			query = self.where(payment_for: Erp::Orders::Order::PAYMENT_FOR_ORDER)

			if params[:from_date].present?
				query = query.where('order_date >= ?', params[:from_date].beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('order_date <= ?', params[:to_date].end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present? # @todo review this function
					query = query.where('order_date >= ? AND order_date <= ?',
															Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
															Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end

			return query
		end

    # Get all orders (payment_for: 'for_contact')
    def self.payment_for_contact_orders(params={})
			query = self.where(payment_for: Erp::Orders::Order::PAYMENT_FOR_CONTACT)

			if params[:from_date].present?
				query = query.where('order_date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('order_date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present? # @todo review this function
					query = query.where('order_date >= ? AND order_date <= ?',
            Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end

			return query
		end

    # Get stock check orders
    def self.stock_check_orders
			self.sales_orders
        .where(status: [Erp::Orders::Order::STATUS_STOCK_CHECKING,
                        Erp::Orders::Order::STATUS_STOCK_CHECKED,
                        Erp::Orders::Order::STATUS_STOCK_APPROVED])
        .order('erp_orders_orders.checking_order IS NULL, erp_orders_orders.checking_order')
		end

    # get need to stock check orders
    def self.stock_checking_orders
			self.sales_orders
        .where(status: [Erp::Orders::Order::STATUS_STOCK_CHECKING])
        .order('erp_orders_orders.checking_order IS NULL, erp_orders_orders.checking_order')
		end

    # Get all active orders
    def self.all_confirmed
      self.where(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end

    # Get all overdue orders
    def self.all_overdue
      self.where(cache_payment_status: Erp::Orders::Order::PAYMENT_STATUS_OVERDUE)
    end

		# SET status for order
		def set_draft
			update_attributes(status: Erp::Orders::Order::STATUS_DRAFT)
		end

		# SET status for order
		def set_stock_checking
			update_attributes(status: Erp::Orders::Order::STATUS_STOCK_CHECKING)
		end

		def set_stock_checked
			update_attributes(status: Erp::Orders::Order::STATUS_STOCK_CHECKED)
		end

		def set_stock_approved
			update_attributes(status: Erp::Orders::Order::STATUS_STOCK_APPROVED)
		end

    def set_confirmed
      update_attributes(status: Erp::Orders::Order::STATUS_CONFIRMED)
    end

    def set_deleted
      update_attributes(status: Erp::Orders::Order::STATUS_DELETED)
    end

    # Get order stock check
    def get_order_stock_check
			schecks.order('updated_at desc').first
		end

    # Check if order details is change
    def is_items_change?(params)
			params.each do |row|
				exist = false
				# check if change quantity
				order_details.each do |od|
					if row[1]["product_id"].to_i == od.product_id
						exist = true
						if row[1]["quantity"].to_i != od.quantity
							return true
						end
					end
				end
				# check if the product is added
				if exist == false
					return true
				end
			end

			# check if the product is removed
			order_details.each do |od|
				exist = false
				params.each do |row|
					if od.product_id == row[1]["product_id"].to_i
						exist = true if !row[1]["_destroy"].present?
						break if (od.product_id == row[1]["product_id"].to_i);
					end
				end
				if exist == false
					return true
				end
			end

			return false
		end

    # Check is details replaced
    def is_details_replaced?
      valid = true
      order_details.each do |od|
        if !od.scheck_detail.present? or
          (!od.scheck_detail.get_alternative_items.include?(od.product) and !od.scheck_detail.available?)
          valid = false
        end
      end
      return valid
      # Thiếu check số lượng
    end

    # Generate code
    before_validation :generate_code
    def generate_code
			if !code.present?
				if sales?
					query = Erp::Orders::Order.where(supplier_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
				elsif purchase?
					query = Erp::Orders::Order.where(customer_id: Erp::Contacts::Contact::MAIN_CONTACT_ID)
				end

				str = (sales? ? 'BH' : 'MH')
				num = query.where('order_date >= ? AND order_date <= ?', self.order_date.beginning_of_month, self.order_date.end_of_month).count + 1

				self.code = str + order_date.strftime("%m") + order_date.strftime("%Y").last(2) + "-" + num.to_s.rjust(3, '0')
			end
		end

    after_save :update_cache_search
		def update_cache_search
			str = []
			str << code.to_s.downcase.strip
			str << customer_name.to_s.downcase.strip if sales?
			str << supplier_name.to_s.downcase.strip if purchase?
			str << warehouse_name.to_s.downcase.strip
			str << employee_name.to_s.downcase.strip
			order_details.each do |od|
        str << od.product_name.to_s.downcase.strip
			end

			self.update_column(:cache_search, str.join(" ") + " " + str.join(" ").to_ascii)
		end

    if Erp::Core.available?("payments")
			# get payment type
			def self.get_payment_type_options()
				[
					{text: I18n.t('orders.payment_for_order'),value: Erp::Orders::Order::PAYMENT_FOR_ORDER},
					{text: I18n.t('orders.payment_for_contact'),value: Erp::Orders::Order::PAYMENT_FOR_CONTACT}
				]
			end

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

			# get done pay payment records for order
			def done_payment_records
				self.payment_records.all_done
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

			# set payment status
			def payment_status
				status = ''
				if self.status == Erp::Orders::Order::STATUS_CONFIRMED
					if remain_amount == 0
						status = Erp::Orders::Order::PAYMENT_STATUS_PAID
					elsif remain_amount > 0
						if self.payment_for == Order::PAYMENT_FOR_CONTACT
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
		end

    if Erp::Core.available?("accounting")

			# Trường hợp đơn hàng đã hủy và (có/đã) thanh toán thì hiển thị thế nào? (Hàm get orders)

			# get sales orders need to payments
			def self.accounting_sales_orders
				self.sales_orders.where(status: Erp::Orders::Order::STATUS_CONFIRMED)
			end

			# get purchase orders need to payments
			def self.accounting_purchase_orders
				self.purchase_orders.where(status: Erp::Orders::Order::STATUS_CONFIRMED)
			end

			# @todo remove this function
			def self.status_active_for_orders
				self.where(status: Erp::Orders::Order::STATUS_ACTIVE)
			end
		end

    def get_name
			return '' if self.code.nil? or self.created_at.nil?

			"#{self.code} (#{self.order_date.strftime('%d/%m/%Y')})".html_safe
		end

    def get_type
			return Order::TYPE_SALES_ORDER if self.sales?
			return Order::TYPE_PURCHASE_ORDER if self.purchase?
			return nil
		end

    def self.get_wait_for_delivery_sales_orders
			Erp::Orders::Order.sales_orders
				.where(status: Erp::Orders::Order::STATUS_CONFIRMED)
				.where(cache_delivery_status: self::DELIVERY_STATUS_NOT_DELIVERY)
		end

    def self.get_wait_for_delivery_purchase_orders
			Erp::Orders::Order.purchase_orders
				.where(status: Erp::Orders::Order::STATUS_CONFIRMED)
				.where(cache_delivery_status: self::DELIVERY_STATUS_NOT_DELIVERY)
		end

    def self.get_waiting_sales_orders
			Erp::Orders::Order.sales_orders
				.where(status: [self::STATUS_STOCK_CHECKED, self::STATUS_STOCK_APPROVED])
		end

    # update cache total for order_detail
    after_save :update_order_detail_cache_total
    def update_order_detail_cache_total
			self.order_details.each do |od|
        od.update_cache_total
      end
		end

    # update cache total real for order_detail (real revenue)
    after_save :update_order_detail_cache_real_revenue
    def update_order_detail_cache_real_revenue
			self.order_details.each do |od|
        od.update_cache_real_revenue
      end
		end

    # --------- Report Functions - Start ---------
    # Doanh thu ban hang
    def self.sales_total_amount(params={})
			query = sales_orders.all_confirmed

			if params[:from_date].present?
				query = query.where('order_date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('order_date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('order_date >= ? AND order_date <= ?',
															Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
															Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end

			# @todo tinh doanh thu ban hang SUM tren cot cache_total hay cache_total_without_customer_commission (co tinh customer-commission khong???)
			return query.sum(:cache_total)
		end

    def self.doanh_thu_sau_khi_da_tru_hang_bi_tra_lai(params={})
			self.sales_total_amount(params) - Erp::Qdeliveries::DeliveryDetail.total_amount_by_delivery_type(params.merge({delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT}))
		end

    # Giá vốn hàng bán
    def self.cost_total_amount(params={})
			query = sales_orders.all_confirmed

			if params[:from_date].present?
				query = query.where('order_date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('order_date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('order_date >= ? AND order_date <= ?',
															Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
															Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end

			# @todo tinh doanh thu ban hang SUM tren cot cache_total hay cache_total_without_customer_commission (co tinh customer-commission khong???)
			return query.sum(:cache_cost_total)
		end

    # Lợi nhuận gộp về bán hàng
    def self.loi_nhuan_gop_ve_ban_hang(params={})
			self.doanh_thu_sau_khi_da_tru_hang_bi_tra_lai(params) - self.cost_total_amount(params)
		end
    # --------- Report Functions - End ---------

    # =========================== COST =======================
    after_save :update_cache_cost_total
    # get sub total amount
    def cost_total
			return order_details.sum(&:cost_total)
		end
    # Update cache total
    def update_cache_cost_total
			self.update_column(:cache_cost_total, self.cost_total)
		end

    after_save :update_default_cost_price
    # Update purchase price
    def update_default_cost_price
      self.order_details.each do |od|
        od.update_default_cost_price
      end
    end
  end
end
