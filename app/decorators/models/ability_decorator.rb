Erp::Ability.class_eval do
  def orders_ability(user)
    can :read, Erp::Orders::FrontendOrder
    
    can :update, Erp::Orders::FrontendOrder do |order|
      if !user.nil?
        order.status == Erp::Orders::FrontendOrder::STATUS_DRAFT or order.status == Erp::Orders::FrontendOrder::STATUS_CONFIRMED
      end
    end
    
    can :delete, Erp::Orders::FrontendOrder do |order|
    end
  end
end