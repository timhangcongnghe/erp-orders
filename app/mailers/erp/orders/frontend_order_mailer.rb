module Erp::Orders
  class FrontendOrderMailer < Erp::ApplicationMailer
    def sending_admin_email_order_confirmation(order)
      # @todo: How to send an order to another email
      @admin = Erp::Contacts::Contact.first
      @order = order
      send_email(@admin.email, "[TimHangCongNghe.vn] Thông báo: Đơn hàng #{@order.code} vừa được đặt trên hệ thống")
    end
    
    def sending_customer_email_order_confirmation(order)
      @order = order
      send_email(@order.customer.email, "[TimHangCongNghe.vn] Xác nhận đặt hàng thành công")
    end
  end
end
