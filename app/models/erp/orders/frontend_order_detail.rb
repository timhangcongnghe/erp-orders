module Erp::Orders
  class FrontendOrderDetail < ApplicationRecord
    #validates :product_id, :presence => true
    belongs_to :frontend_order
    belongs_to :product, class_name: 'Erp::Products::Product'
    
    before_validation :update_current_price_from_product
    before_validation :update_current_name_from_product
    
    def update_current_price_from_product
      if self.price.nil?
        self.price = product.product_price
      end    
    end
      
    def update_current_name_from_product
      if self.product_name.nil?
        self.product_name = product.name
      end    
    end
  end
end
