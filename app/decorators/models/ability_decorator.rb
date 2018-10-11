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
      order.is_draft? or order.is_stock_checking? or order.is_stock_checked? or order.is_stock_approved? or order.is_confirmed?
    end

    can :print, Erp::Orders::Order do |order|
      order.is_confirmed? and order.is_delivered?
    end

    can :xlsx_export, Erp::Orders::Order do |order|
      order.is_confirmed?
    end

    can :set_stock_checking, Erp::Orders::Order do |order|
      if order.sales?
        order.is_draft?
      end
    end

    can :confirm, Erp::Orders::Order do |order|
      if order.sales?
        order.is_draft? or order.is_stock_checked? or order.is_stock_approved?
      else
        order.is_draft?
      end
    end

    can :delete, Erp::Orders::Order do |order|
      order.is_draft? or
      (
        (
          order.is_stock_checking? or order.is_stock_checked? or order.is_stock_approved?  or order.is_confirmed?
        ) and 
        (
          if order.sales?
           user.get_permission(:sales, :sales, :orders, :delete) == 'yes'
          else
            user.get_permission(:purchase, :purchase, :orders, :delete) == 'yes'
          end
        )
      )
    end

    can :update, Erp::Orders::Order do |order|
      order.is_draft? or
      (
        (
          order.is_stock_checking? or order.is_stock_checked? or order.is_stock_approved? or order.is_confirmed?
        ) and
        (
          if order.sales?
            user.get_permission(:sales, :sales, :orders, :update) == 'yes' or
            (
              user.get_permission(:sales, :sales, :orders, :update) == 'in_day' and
              (
                order.confirmed_at.nil? or (Time.now < order.confirmed_at.end_of_day and order.is_confirmed?)
              )
            )
          else
            user.get_permission(:purchase, :purchase, :orders, :update) == 'yes' or
            (
              user.get_permission(:purchase, :purchase, :orders, :update) == 'in_day' and
              (
                order.confirmed_at.nil? or (Time.now < order.confirmed_at.end_of_day and order.is_confirmed?)
              )
            )
          end
        )
      )
    end
    
    can :create, Erp::Orders::Order do |order|
      if order.sales?
        user.get_permission(:sales, :sales, :orders, :create) == 'yes'
      else
        user.get_permission(:purchase, :purchase, :orders, :create) == 'yes'
      end
    end

    can :sales_export, Erp::Orders::Order do |order|
      order.is_confirmed? and !order.is_delivered? and order.sales?
    end

    can :purchase_import, Erp::Orders::Order do |order|
      order.is_confirmed? and !order.is_delivered? and order.purchase?
    end
  end
end
