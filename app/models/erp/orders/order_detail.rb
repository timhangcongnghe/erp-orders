module Erp::Orders
  class OrderDetail < ApplicationRecord
    validates :product_id, :quantity, :price, :presence => true
    belongs_to :order, class_name: 'Erp::Orders::Order'
    belongs_to :product, class_name: 'Erp::Products::Product'
    if Erp::Core.available?("order_stock_checks")
    has_one :scheck_detail, class_name: 'Erp::OrderStockChecks::ScheckDetail', dependent: :destroy
		end
    after_save :update_order_cache_payment_status
    after_save :update_order_cache_delivery_status
    after_save :update_order_cache_total
    after_save :update_order_cache_tax_amount
    after_save :update_order_cache_commission_amount
    after_save :update_order_cache_customer_commission_amount

    STATUS_NOT_DELIVERY = 'not_delivery'
    STATUS_DELIVERED = 'delivered'
    STATUS_OVER_DELIVERED = 'over_delivered'

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

    if Erp::Core.available?("qdeliveries")
			after_save :order_update_cache_delivery_status

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

    # update order cache payment status
    def update_order_cache_payment_status
			if order.present?
				order.update_cache_payment_status
			end
		end

    # update order cache payment status
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
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_CUSTOMER_IMPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')
				export_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_WAREHOUSE_EXPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')
				return export_quantity - import_quantity
			elsif order.purchase?
				import_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_WAREHOUSE_IMPORT})
													.sum('erp_qdeliveries_delivery_details.quantity')
				export_quantity = self.delivered_delivery_details
													.where(erp_qdeliveries_deliveries: {delivery_type: Erp::Qdeliveries::Delivery::TYPE_MANUFACTURER_EXPORT})
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
      product.nil? ? '' : product.product_price
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
			quantity*price
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
			subtotal + shipping_amount - discount_amount
		end

    # tax amount
    def tax_amount
			count = 0
			if order.tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_FIXED
				count = order.tax.amount
			elsif order.tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_PRICE
				count = (total_without_tax*(order.tax.amount))/100
			end
			return count
		end

    # total after tax
    def total
			total_without_tax + tax_amount
		end

  end
end
