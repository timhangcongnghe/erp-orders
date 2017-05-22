Erp::User.class_eval do
  has_many :frontend_orders, class_name: 'Erp::Orders::FrontendOrder', foreign_key: 'creator_id'
  
  # get frontend orders for user
  def get_frontend_orders_for_user
    frontend_orders.where(erp_orders_frontend_orders: {creator_id: self.id})
  end
  
  # Order statistics
  def orders_being_traded
    get_frontend_orders_for_user.where(status: Erp::Orders::FrontendOrder::STATUS_IS_ACTIVE)
  end
  
  def orders_completed
    get_frontend_orders_for_user.where(status: Erp::Orders::FrontendOrder::STATUS_FINISHED)
  end
  
  def orders_cancelled
    get_frontend_orders_for_user.where(status: Erp::Orders::FrontendOrder::STATUS_CANCELLED)
  end
  
  # Tong so luong san pham cua don hang da giao dich thanh cong
  def number_of_products_purchased
    Erp::Orders::FrontendOrderDetail.joins(:frontend_order)
      .where(erp_orders_frontend_orders: {creator_id: self.id})
      .where(erp_orders_frontend_orders: {status: Erp::Orders::FrontendOrder::STATUS_FINISHED})
      .sum(:quantity)
  end
  
  # Tong so tien cua don hang da giao dich thanh cong
  def total_amount_for_orders_completed
    amount = 0
    self.orders_completed.each do |o|
      amount += o.cache_total.to_f
    end
    return amount
  end
end