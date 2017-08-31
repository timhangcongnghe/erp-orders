module Erp::Orders
  class OrderDetail < ApplicationRecord
    validates :product_id, :quantity, :price, :presence => true
    belongs_to :order, class_name: 'Erp::Orders::Order'
    belongs_to :product, class_name: 'Erp::Products::Product'
    after_save :update_order_cache_payment_status
    after_save :update_order_cache_delivery_status
    after_save :update_order_cache_total
    after_save :update_order_cache_tax_amount
    
    STATUS_NOT_DELIVERY = 'not_delivery'
    STATUS_DELIVERED = 'delivered'
    STATUS_OVER_DELIVERED = 'over_delivered'
    
    if Erp::Core.available?("qdeliveries")
			after_save :order_update_cache_delivery_status
			
			has_many :delivery_details, class_name: "Erp::Qdeliveries::DeliveryDetail"
			
			def get_delivered_deliveries
				self.delivery_details.joins(:delivery)
													.where(erp_qdeliveries_deliveries: {status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED})												
			end
			
			def delivered_delivery
				self.delivery_details.joins(:delivery)
													.where(erp_qdeliveries_deliveries: {status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED})												
			end
			
			def delivered_quantity
				delivered_delivery.sum('erp_qdeliveries_delivery_details.quantity')
			end
			
			def not_delivery_quantity
				quantity - delivered_quantity
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
    
    def delivered_amount
			import_amount = self.delivery_details.joins(:delivery)
													.where(erp_deliveries_deliveries: {delivery_type: Erp::Deliveries::Delivery::TYPE_IMPORT})
													.sum('erp_deliveries_delivery_details.quantity')
			export_amount = self.delivery_details.joins(:delivery)
													.where(erp_deliveries_deliveries: {delivery_type: Erp::Deliveries::Delivery::TYPE_EXPORT})
													.sum('erp_deliveries_delivery_details.quantity')
													
			if order.sales?
				return export_amount - import_amount
			elsif order.purchase?
				return -export_amount + import_amount
			else
				return 0
			end
		end
    
    def remain_quantity
			quantity - delivered_amount
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
