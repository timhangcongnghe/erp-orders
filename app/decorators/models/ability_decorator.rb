Erp::Ability.class_eval do
  def orders_ability(user)
    
    # Cancan for Frontend Order
    can :read, Erp::Orders::FrontendOrder
    
    can :update, Erp::Orders::FrontendOrder do |order|
      if !user.nil?
        order.status == Erp::Orders::FrontendOrder::STATUS_DRAFT or order.status == Erp::Orders::FrontendOrder::STATUS_CONFIRMED
      end
    end
    
    can :delete, Erp::Orders::FrontendOrder do |order|
    end
    # END: Cancan for Frontend Order
    
    # Cancan for Order
    can :read, Erp::Orders::Order do |order|
      order.is_draft? or order.is_confirmed?
    end
    
    can :set_stock_checking, Erp::Orders::Order do |order|
      if order.sales?
        order.is_draft? or order.is_stock_checked? or order.is_stock_approved? or order.is_deleted?
      end
    end
    
    can :set_stock_checked, Erp::Orders::Order do |order|
      if order.sales?
        order.is_stock_checking?
      end
    end
    
    can :set_stock_approved, Erp::Orders::Order do |order|
      if order.sales?
        order.is_stock_checking?
      end
    end
    
    can :confirm, Erp::Orders::Order do |order|
      if order.sales?
        order.is_stock_approved?
      else
        order.is_draft? or order.is_deleted?
      end
    end
    
    can :delete, Erp::Orders::Order do |order|
      order.is_draft? or order.is_confirmed?
    end
    
    can :update, Erp::Orders::Order do |order|
      order.is_draft? or order.is_confirmed? or order.is_deleted?
    end
  end
end