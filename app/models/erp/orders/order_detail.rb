module Erp::Orders
  class OrderDetail < ApplicationRecord
    validates :product_id, :quantity, :price, :presence => true
    belongs_to :order, class_name: 'Erp::Orders::Order'
    belongs_to :product, class_name: 'Erp::Products::Product'    
    after_save :order_update_cache_payment_status
    after_save :order_update_cache_delivery_status
    after_save :update_order_cache_total
    
    if Erp::Core.available?("deliveries")
			has_many :delivery_details, class_name: "Erp::Deliveries::DeliveryDetail"
			
			def delivered_delivery
				self.delivery_details.joins(:delivery)
													.where(erp_deliveries_deliveries: {status: Erp::Deliveries::Delivery::DELIVERY_STATUS_DELIVERED})												
			end
			
			def delivered_quantity
				delivered_delivery.sum('erp_deliveries_delivery_details.quantity')
			end
			
			def not_delivered_quantity
				quantity - delivered_quantity
			end			
		end
    
    STATUS_NOT_DELIVERY = 'not_delivery'
    STATUS_DELIVERED = 'delivered'
    STATUS_OVER_DELIVERED = 'over_delivered'
    
    # update order tax amount
    def update_order_tax_amount
			if order.present?
				order.update_tax_amount
			end
		end
    
    # update order cache total
    def update_order_cache_total
			if order.present?
				order.update_cache_total
			end
		end
    
    # update order cache payment status
    def order_update_cache_payment_status
			if order.present?
				order.update_cache_payment_status
			end
		end
    
    # update order cache payment status
    def order_update_cache_delivery_status
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
    
    # @todo validates
    def total_amount
			quantity*price
		end
    
    def total
			total_amount - get_discount + get_shipping_fee
		end
    
    def get_discount
			discount.nil? ? 0.0 : discount
    end
    
    def get_shipping_fee
			shipping_fee.nil? ? 0.0 : shipping_fee
    end
    
  end
end
