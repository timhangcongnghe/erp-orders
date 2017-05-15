module Erp::Orders
  class FrontendOrderMailer < Erp::ApplicationMailer
    def sending_admin_email_order_confirmation(order)
      # @todo: How to send an order to another email
      # @admin = Erp::Contacts::Contact.first
      # @todo static emails
      @recipients = ['Hùng Nguyễn <hungnt@hoangkhang.com.vn>']#, 'Luân Phạm <luanpm@hoangkhang.com.vn>', 'Sơn Nguyễn <sonnn@hoangkhang.com.vn>']
      
      @order = order
      send_email(@recipients.join("; "), "##{@order.code} - Thông tin đơn hàng vừa được đặt trên hệ thống")
    end
    
    def sending_customer_email_order_confirmation(order)
      @order = order
      send_email(@order.customer.email, "##{@order.code} - Xác nhận đặt hàng thành công")
    end
  end
end
