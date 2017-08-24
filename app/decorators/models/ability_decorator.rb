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
    can :confirm, Erp::Orders::Order do |order|
      order.is_draft? or order.is_deleted?
    end
    
    can :delete, Erp::Orders::Order do |order|
      order.is_draft? or order.is_confirmed?
    end
    
    can :update, Erp::Orders::Order do |order|
      order.is_draft? or order.is_confirmed?
    end
  end
end