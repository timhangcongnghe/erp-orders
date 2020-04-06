module Erp::Orders
  class FrontendOrderMailer < Erp::ApplicationMailer
    helper Erp::ApplicationHelper

    if Erp::Core.available?("online_store")
      helper Erp::OnlineStore::ApplicationHelper
    end

    def sending_admin_email_order_confirmation(order)
      # @todo: How to send an order to another email
      # @admin = Erp::Contacts::Contact.first
      # @todo static emails
      @recipients = ['Kinh Doanh <kinhdoanh@hoangkhang.com.vn>', 'Trương Thị Thanh Huyền <huyenttt@hoangkhang.com.vn>', 'Đỗ Thị Đa Nguyên <nguyendtd@hoangkhang.com.vn>', 'Sơn Nguyễn <sonnn@hoangkhang.com.vn>']

      @order = order
      send_email(@recipients.join("; "), "##{@order.code} - Thông tin đơn hàng vừa được đặt trên hệ thống")
    end

    def sending_customer_email_order_confirmation(order)
      @order = order
      send_email(@order.customer.email, "##{@order.code} - Xác nhận đặt hàng thành công")
    end
  end
end
