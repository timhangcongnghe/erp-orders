module Erp::Orders
  class OrderDetail < ApplicationRecord
    validates :product_id, :presence => true
    belongs_to :order
    belongs_to :product, class_name: 'Erp::Products::Product'
    if Erp::Core.available?("deliveries")
			has_many :delivery_details, class_name: "Erp::Deliveries::DeliveryDetail"
		end
    after_save :order_update_cache_payment_status
    
    def order_update_cache_payment_status
			if order.present?
				order.update_cache_payment_status
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
				return nil
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
      product.nil? ? '' : product.price
    end
  end
end
