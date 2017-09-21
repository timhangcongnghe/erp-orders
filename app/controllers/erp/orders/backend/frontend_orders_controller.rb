module Erp
  module Orders
    module Backend
      class FrontendOrdersController < Erp::Backend::BackendController
        before_action :set_order, only: [:show, :edit, :update, :destroy, :set_confirm, :set_finish, :set_cancel]
        before_action :set_orders, only: [:delete_all, :set_confirm_all, :set_finish_all, :set_cancel_all]
        
        def index
        end
        
        def list
          @orders = Erp::Orders::FrontendOrder.search(params).paginate(:page => params[:page], :per_page => 5)
          
          render layout: nil
        end
        
        def frontend_order_details
          @order = FrontendOrder.find(params[:id])
          
          render layout: nil
        end
        
        def edit
          authorize! :update, @order
        end
        
        # PATCH/PUT /orders/1
        def update
          if @order.update(frontend_order_params)
            if request.xhr?
              render json: {
                status: 'success',
                text: @order.code,
                value: @order.id
              }              
            else
              redirect_to erp_orders.edit_backend_frontend_order_path(@frontend_order), notice: t('.success')
            end
          else
            render :edit
          end
        end
        
        def frontend_order_line_form
          @order_detail = Erp::Orders::FrontendOrderDetail.new
          @order_detail.product_id = params[:add_value]
          
          render partial: params[:partial], locals: {
            order_detail: @order_detail,
            uid: helpers.unique_id()
          }
        end
    
        # DELETE /orders/1
        def destroy
          @order.destroy
          
          respond_to do |format|
            format.html { redirect_to erp_orders.backend_frontend_orders_path, notice: t('.success') }
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end
        
        # DELETE /orders/delete_all?ids=1,2,3
        def delete_all         
          @orders.destroy_all
          
          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end          
        end
        
        # dataselect /orders
        def dataselect
          respond_to do |format|
            format.json {
              render json: FrontendOrder.dataselect(params[:keyword])
            }
          end
        end
        
        # Confirm /orders/set_confirm?id=1
        def set_confirm
          @order.set_confirm
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Finish /orders/set_finish?id=1
        def set_finish
          @order.set_finish
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Cancel /orders/set_cancel?id=1
        def set_cancel
          @order.set_cancel
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Confirm /orders/set_confirm_all?ids=1,2,3
        def set_confirm_all
          @orders.set_confirm_all
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Finish /orders/set_finish_all?ids=1,2,3
        def set_finish_all
          @orders.set_finish_all
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Cancel /orders/set_cancel_all?ids=1,2,3
        def set_cancel_all
          @orders.set_cancel_all
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        private
          # Use callbacks to share common setup or constraints between actions.
          def set_order
            @order = FrontendOrder.find(params[:id])
          end
          
          def set_orders
            @orders = FrontendOrder.where(id: params[:ids])
          end
    
          # Only allow a trusted parameter "white list" through.
          def frontend_order_params
            params.fetch(:order, {}).permit(:frontend_order_details_attributes => [ :id, :product_id, :frontend_order_id, :quantity, :price, :description, :_destroy ])
          end
      end
    end
  end
end
