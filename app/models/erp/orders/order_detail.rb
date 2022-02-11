module Erp::Orders
  class OrderDetail < ApplicationRecord
    validates :product_id, :quantity, :presence => true
    belongs_to :order, class_name: 'Erp::Orders::Order'
    belongs_to :product, class_name: 'Erp::Products::Product'
    
    if Erp::Core.available?("warehouses")
      belongs_to :warehouse, class_name: "Erp::Warehouses::Warehouse"
      
      def warehouse_name
        self.warehouse.present? ? self.warehouse.name : ''
      end
    end
    
    if Erp::Core.available?("order_stock_checks")
    has_one :scheck_detail, -> { order created_at: :desc }, class_name: 'Erp::OrderStockChecks::ScheckDetail', dependent: :destroy
		end
    after_save :update_order_cache_payment_status
    # after_save :update_order_cache_delivery_status
    after_save :update_order_cache_total
    after_save :update_order_cache_cost_total
    after_save :update_order_cache_tax_amount
    after_save :update_order_cache_commission_amount
    after_save :update_order_cache_customer_commission_amount
    after_save :update_cache_delivery_status

    DELIVERY_STATUS_NOT_DELIVERY = 'not_delivery'
    DELIVERY_STATUS_DELIVERED = 'delivered'
    DELIVERY_STATUS_OVER_DELIVERED = 'over_delivered'

    before_validation :check_price

    def check_price
      self.price = 0 if self.price.nil?
    end

    def is_delivered?
			self.delivery_status == OrderDetail::DELIVERY_STATUS_DELIVERED
		end

    def price=(new_price)
      self[:price] = new_price.to_s.gsub(/\,/, '')
    end
    def discount=(new_price)
      self[:discount] = new_price.to_s.gsub(/\,/, '')
    end
    def shipping_fee=(new_price)
      self[:shipping_fee] = new_price.to_s.gsub(/\,/, '')
    end
    def commission=(new_price)
      self[:commission] = new_price.to_s.gsub(/\,/, '')
    end
    def customer_commission=(new_price)
      self[:customer_commission] = new_price.to_s.gsub(/\,/, '')
    end
    def quantity=(number)
      self[:quantity] = number.to_s.gsub(/\,/, '')
    end
    def cost_price=(new_price)
      self[:cost_price] = new_price.to_s.gsub(/\,/, '')
    end

    if Erp::Core.available?("qdeliveries")
			# after_save :order_update_cache_delivery_status

			has_many :delivery_details, class_name: "Erp::Qdeliveries::DeliveryDetail"

			def delivered_delivery_details
				self.delivery_details.joins(:delivery)
					.where(erp_qdeliveries_deliveries: {status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED})
			end

			# order update cache payment status
			def order_update_cache_delivery_status
				if order.present?
					order.update_cache_delivery_status
				end
			end
			
			def get_delivery_warehouse_export
        query = self.delivered_delivery_details
        if order.sales?
          query = query.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT})
          query = query.map{ |dd| dd.warehouse_name }.uniq.join(', ')
        elsif order.purchase?
          query = query.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT})
          query = query.map{ |dd| dd.warehouse_name }.uniq.join(', ')
        else
          return '--'
        end
      end
			
			def get_delivery_warehouse_import
        query = self.delivered_delivery_details
        if order.sales?
          query = query.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT})
          query = query.map{ |dd| dd.warehouse_name }.uniq.join(', ')
        elsif order.purchase?
          query = query.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT})
          query = query.map{ |dd| dd.warehouse_name }.uniq.join(', ')
        else
          return '--'
        end
      end

		end

    # update order cache tax amount
    def update_order_cache_tax_amount
			if order.present?
				order.update_cache_tax_amount
			end
		end

    # update order cache commission amount
    def update_order_cache_commission_amount
			if order.present?
				order.update_cache_commission_amount
			end
		end

    # update order cache customer commission amount
    def update_order_cache_customer_commission_amount
			if order.present?
				order.update_cache_customer_commission_amount
			end
		end

    # update order cache total
    def update_order_cache_total
			if order.present?
				order.update_cache_total
			end
		end

    # update order cache cost total
    def update_order_cache_cost_total
			if order.present?
				order.update_cache_cost_total
			end
		end

    # Update cache total (total after tax)
    after_save :update_cache_total
    def update_cache_total
			self.update_column(:cache_total, self.total)
		end

    # Update cache total real (real revenue)
    after_save :update_cache_real_revenue
    def update_cache_real_revenue
			self.update_column(:cache_real_revenue, self.real_revenue)
		end

    # update order cache payment status
    def update_order_cache_payment_status
			if order.present?
				order.update_cache_payment_status
			end
		end

    # update order cache delivery status
    def update_order_cache_delivery_status
			if order.present?
				order.update_cache_delivery_status
			end
		end

    def self.search(params)
      query = self.all
      query = query.where(product_id: params[:product_id])
      return query
    end

    def delivered_quantity
			if order.sales?
				import_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')
				export_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')
				return export_quantity - import_quantity
			elsif order.purchase?
				import_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')
				export_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')

				return -export_quantity + import_quantity
			else
				return 0
			end
		end

    def not_delivered_quantity
			quantity - delivered_quantity
		end

    def product_code
      product.nil? ? '' : product.code
    end

    def product_name
      product.nil? ? '' : product.name
    end

    def product_price
      product.nil? ? '' : product.get_show_price
    end

    def product_category_name
			product.nil? ? '' : product.category_name
		end

    def product_unit_name
			if !product.nil?
				product.unit.nil? ? '' : product.unit.name
			end
		end

    # @todo validates when quantity nil?
    def subtotal
			quantity.to_f*price.to_f
		end

    # get shipping amount
    def shipping_amount
			shipping_fee.nil? ? 0.0 : shipping_fee
		end

    # get discount amount
    def discount_amount
			discount.nil? ? 0.0 : discount
		end

    # get commission amount
    def commission_amount
			commission.nil? ? 0.0 : commission
		end

    # get customer commission amount
    def customer_commission_amount
			customer_commission.nil? ? 0.0 : customer_commission
		end

    # total before tax
    def total_without_tax
			subtotal - discount_amount
		end
    
    # unit price
    def unit_price
      total_without_tax/quantity
    end

    # tax amount
    def tax_amount
			count = 0
			if order.tax.present?
        if order.tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_FIXED
          count = order.tax.amount
        elsif order.tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_PRICE
          count = (total_without_tax*(order.tax.amount))/100
        end
      end
			return count
		end

    # total after tax
    def total
			total_without_tax + tax_amount
		end

    # total without commissions + customer_commisions, real revenue
    def real_revenue
      total - commission_amount - customer_commission_amount
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

    # total cost
    def cost_total
			quantity.to_f*cost_price.to_f
		end

    if Erp::Core.available?("ortho_k")
      belongs_to :request_product, class_name: 'Erp::Products::Product'

      before_validation :update_request_product
      def update_request_product
        self.request_product_id = self.product_id if self.request_product_id.nil?
      end

      # Get default price
      def get_default_price
        Erp::Prices::Price.get_by_product(contact_id: self.order.customer.id,
          category_id: self.product.category_id,
          properties_value_id: self.product.get_properties_value(Erp::Products::Property.getByName(Erp::Products::Property::NAME_DUONG_KINH)),
          quantity: self.quantity, type: Erp::Prices::Price::TYPE_SALES
        )
      end

      def get_default_purchase_price
        self.product.get_default_purchase_price(
          contact_id: (self.order.supplier.present? ? self.order.supplier.id : nil),
          quantity: self.quantity
        )
      end
		end

    after_save :update_default_cost_price
    # Update purchase price
    def update_default_cost_price
      if cost_price.to_f == 0.0
        p_price = get_default_purchase_price
        if p_price.present?
          update_attribute(:cost_price, p_price.price)
        end
      end
    end
    
    # get all active order details
    def self.get_sales_confirmed_order_details(options={})
      query = Erp::Orders::OrderDetail.joins(:order)
        .where(erp_orders_orders: {status: Erp::Orders::Order::STATUS_CONFIRMED})
        .where(erp_orders_orders: {supplier_id: Erp::Contacts::Contact.get_main_contact.id})

      if options[:from_date].present?
				query = query.where('erp_orders_orders.order_date >= ?', options[:from_date].to_date.beginning_of_day)
			end

			if options[:to_date].present?
				query = query.where('erp_orders_orders.order_date <= ?', options[:to_date].to_date.end_of_day)
			end

			if options[:customer_id].present?
				query = query.where(erp_orders_orders: {customer_id: options[:customer_id]})
			end
			
			if options[:patient_state_id] == -1
        query = query.where(erp_orders_orders: {patient_state_id: nil})
      end
			
			if Erp::Core.available?("ortho_k")
        if options[:patient_state_id].present? and options[:patient_state_id] != -1
          if options[:patient_state_id] == -2
            query = query.where(erp_orders_orders: {patient_state_id: nil})
          else
            query = query.where('erp_orders_orders.patient_state_id = ?', options[:patient_state_id])
          end
        end
      end

			if Erp::Core.available?("periods")
				if options[:period].present?
					query = query.where('erp_orders_orders.order_date >= ? AND erp_orders_orders.order_date <= ?',
            Erp::Periods::Period.find(options[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(options[:period]).to_date.end_of_day)
				end
			end
			
			query
    end
    
    # find serials from scheck details
    def serials
      return self[:serials] if self[:serials].present?
      se = (scheck_detail.present? and scheck_detail.serials.present?) ? scheck_detail.serials : nil
      return se
    end
  end
end
