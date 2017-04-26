module Erp
  module Orders
    module Backend
      class FrontendOrdersController < Erp::Backend::BackendController
        
        def index
        end
        
        def list
          @frontend_orders = FrontendOrder.all.paginate(:page => params[:page], :per_page => 5)
          
          render layout: nil
        end
        
        def frontend_order_details
          @frontend_order = FrontendOrder.find(params[:id])
          
          render layout: nil
        end
      end
    end
  end
end
