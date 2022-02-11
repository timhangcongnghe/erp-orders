module Erp::Orders
  class FrontendOrderDetail < ApplicationRecord
    #validates :product_id, :presence => true
    belongs_to :frontend_order
    belongs_to :product, class_name: 'Erp::Products::Product'
    
    before_validation :update_current_price_from_product
    before_validation :update_current_name_from_product
    
    after_save :update_frontend_order_cache_total
    
    def update_current_price_from_product
      if self.price.nil?
        self.price = product.get_show_price
      end    
    end
      
    def update_current_name_from_product
      if self.product_name.nil?
        self.product_name = product.name
      end    
    end
    
    # update order cache total
    def update_frontend_order_cache_total
			if frontend_order.present?
				frontend_order.update_cache_total
			end
		end
    
    # class const
    STYLE_GIFT = 'gift'
    
    def total
      quantity*price
    end
    
    # display product code
    def product_code
			product.present? ? product.code : ""
		end
    
    # display product name
    def display_product_name
			product.present? ? product.name : ""
		end
  end
end
