module Erp::Orders
  class OrderDetail < ApplicationRecord
    
    validates :product_id, :presence => true
    belongs_to :order
    belongs_to :product, class_name: 'Erp::Products::Product'
    
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
