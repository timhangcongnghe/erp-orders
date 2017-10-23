module Erp
  module Orders
    module ApplicationHelper
      
      # Order dropdown actions
      def order_dropdown_actions(order)
        actions = []
        actions << {
          text: '<i class="fa fa-file-text-o"></i> '+t('.view'),
          url: erp_orders.backend_order_path(order)
        } if can? :read, order
        actions << {
          text: '<i class="fa fa-edit"></i> '+t('.edit'),
          url: erp_orders.edit_backend_order_path(order)
        } if can? :update, order
        actions << {
          text: '<i class="fa fa-share-square-o"></i> '+t('orders.set_stock_checking'),
          url: erp_orders.set_stock_checking_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: t('orders.set_stock_checking_confirm')
        } if can? :set_stock_checking, order
        actions << {
          text: '<i class="fa fa-check-square-o"></i> '+(order.is_deleted? == false ? t('.set_confirmed') : t('.re_opened')),
          url: erp_orders.set_confirmed_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: order.is_deleted? == false ? t('.set_confirmed_confirm') : t('.re_opened_confirm')
        } if can? :confirm, order
        actions << {
          text: '<i class="fa fa-close"></i> '+t('.set_deleted'),
          url: erp_orders.set_deleted_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: t('.set_deleted_confirm')
        } if can? :delete, order
        if Erp::Core.available?("deliveries")
          actions << { divider: true }
          actions << {
            text: '<i class="fa fa-arrow-up"></i> '+t('.export'),
            url: erp_deliveries.new_backend_delivery_path(type: Erp::Deliveries::Delivery::TYPE_EXPORT, order_id: order.id),
            hide: !order.sales?
          }
          actions << {
            text: '<i class="fa fa-arrow-down"></i> '+t('.import'),
            url: erp_deliveries.new_backend_delivery_path(type: Erp::Deliveries::Delivery::TYPE_IMPORT, order_id: order.id),
            hide: !order.purchase?
          }
        end
        actions << { divider: true }
        actions << {
          text: '<i class="icon-action-undo"></i> '+(order.purchase? ? t('.pay_ncc') : t('.pay_kh')),
          url: erp_payments.new_backend_payment_record_path(order_id: order.id, payment_type: Erp::Payments::PaymentRecord::TYPE_PAY),
        }
        actions << {
          text: '<i class="icon-action-redo"></i> '+(order.purchase? ? t('.receive_ncc') : t('.receive_kh')),
          url: erp_payments.new_backend_payment_record_path(order_id: order.id, payment_type: Erp::Payments::PaymentRecord::TYPE_RECEIVE),
        }
        actions << {
          text: '<i class="icon-refresh"></i> '+t('.extend_debt_deadline'),
          url: erp_payments.new_backend_debt_path(order_id: order.id),
        }
        actions << { divider: true } if !order.payment_records.empty?
        order.payment_records.each do |payment_record|
          actions << {
            text: '<i class="fa fa-print"></i> '+t('.payment_record')+' ('+payment_record.code+')',
            url: erp_payments.backend_payment_record_path(payment_record),
          }
        end
        
        erp_datalist_row_actions(
          actions
        )
      end
      
      # order link helper
      def order_link(order, text=nil)
        text = text.nil? ? order.code : text
        raw "<a href='#{erp_orders.backend_order_path(order)}' class='modal-link'>#{text}</a>"
      end
      
    end
  end
end
