module Erp
  module Orders
    module ApplicationHelper
      
      # Order dropdown actions
      def order_dropdown_actions(order)
        actions = []
        actions << {
          text: '<i class="icon-docs"></i> '+t('.view'),
          url: erp_orders.backend_order_path(order)
        }
        actions << {
          text: '<i class="fa fa-edit"></i> '+t('.edit'),
          url: erp_orders.edit_backend_order_path(order)
        }
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
        actions << { divider: true }
        actions << {
          text: '<i class="icon-action-undo"></i> '+(order.purchase? ? t('.pay_ncc') : t('.pay_kh')),
          url: erp_payments.new_backend_payment_record_path(order_id: order.id, payment_type: Erp::Payments::PaymentRecord::PAYMENT_TYPE_PAY),
        }
        actions << {
          text: '<i class="icon-action-redo"></i> '+(order.purchase? ? t('.receive_ncc') : t('.receive_kh')),
          url: erp_payments.new_backend_payment_record_path(order_id: order.id, payment_type: Erp::Payments::PaymentRecord::PAYMENT_TYPE_RECEIVE),
        }
        actions << {
          text: '<i class="icon-refresh"></i> '+t('.extend_debt_deadline'),
          url: erp_payments.new_backend_debt_path(order_id: order.id),
        }
        actions << { divider: true }
        actions << {
          text: '<i class="fa fa-check"></i> '+(order.deleted? == false ? t('.set_confirmed') : t('.re_opened')),
          url: erp_orders.set_confirmed_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: order.deleted? == false ? t('.set_confirmed_confirm') : t('.re_opened_confirm')
        }
        actions << {
          text: '<i class="fa fa-ban"></i> '+t('.set_deleted'),
          url: erp_orders.set_deleted_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: t('.set_deleted_confirm')
        }
        actions << { divider: true }
        order.payment_records.each do |payment_record|
          actions << {
            text: '<i class="fa fa-print"></i> '+t('.payment_record')+' ('+payment_record.code+')',
            url: erp_payments.backend_payment_record_path(payment_record),
          }
        end
        actions << { divider: true } if !order.payment_records.empty?
        actions << {
          text: '<i class="fa fa-trash"></i> '+t('.delete'),
          url: erp_orders.backend_order_path(order),
          data_method: 'DELETE',
          data_confirm: t('.delete_confirm'),
          class: 'ajax-link'
        }
        
        erp_datalist_row_actions(
          actions
        )
      end
    end
  end
end
