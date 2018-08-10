module Erp
  module Orders
    module ApplicationHelper

      # Order dropdown actions
      def order_dropdown_actions(order)
        actions = []
        actions << {
          text: '<i class="fa fa-print"></i> Xem & In HĐ',
          url: erp_orders.backend_order_path(order),
          class: 'modal-link'
        } if can? :print, order
        actions << {
          text: '<i class="fa fa-file-excel-o"></i> Xuất excel',
          url: erp_orders.xlsx_backend_orders_path(id: order.id, format: 'xlsx'),
          target: '_blank'
        } if can? :xlsx_export, order
        actions << {
          text: '<i class="fa fa-edit"></i> ' + t('.edit'),
          url: erp_orders.edit_backend_order_path(order)
        } if can? :update, order
        actions << {
          text: '<i class="fa fa-share-square-o"></i> ' + t('orders.set_stock_checking'),
          url: erp_orders.set_stock_checking_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: t('orders.set_stock_checking_confirm')
        } if can? :set_stock_checking, order
        actions << {
          text: '<i class="fa fa-check-square-o"></i> ' + (order.is_deleted? == false ? t('.set_confirmed') : t('.re_opened')),
          url: erp_orders.set_confirmed_backend_orders_path(id: order),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: order.is_deleted? == false ? t('.set_confirmed_confirm') : t('.re_opened_confirm')
        } if can? :confirm, order
        actions << {
          text: '<i class="icon-action-redo"></i> Xuất kho',
          url: erp_qdeliveries.new_backend_delivery_path(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT, order_id: order.id),
        } if can? :sales_export, order
        actions << {
          text: '<i class="icon-action-redo"></i> Nhập kho',
          url: erp_qdeliveries.new_backend_delivery_path(delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT, order_id: order.id),
        } if can? :purchase_import, order
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
