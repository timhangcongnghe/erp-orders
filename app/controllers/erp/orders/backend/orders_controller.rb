require_dependency "erp/application_controller"

module Erp
  module Orders
    module Backend
      class OrdersController < Erp::Backend::BackendController
        before_action :set_order, only: [:show, :edit, :update, :destroy, :archive, :unarchive, :set_draft, :set_confirm, :set_cancel]
        before_action :set_orders, only: [:archive_all, :unarchive_all, :delete_all, :set_draft_all, :set_confirm_all, :set_cancel_all]
    
        # GET /orders
        def index
        end
        
        # POST /orders/list
        def list
          @orders = Order.search(params).paginate(:page => params[:page], :per_page => 3)
          
          render layout: nil
        end
    
        # GET /orders/1
        def show
        end
    
        # GET /orders/new
        def new
          @order = Order.new
          @order.order_date = Time.now
          
          if request.xhr?
            render '_form', layout: nil, locals: {order: @order}
          end
        end
    
        # GET /orders/1/edit
        def edit
        end
    
        # POST /orders
        def create
          @order = Order.new(order_params)
          @order.creator = current_user
    
          if @order.save
            if request.xhr?
              render json: {
                status: 'success',
                text: @order.id,
                value: @order.id
              }
            else
              redirect_to erp_orders.edit_backend_order_path(@order), notice: t('.success')
            end
          else
            if request.xhr?
              render '_form', layout: nil, locals: {order: @order}
            else
              render :new
            end
          end
        end
    
        # PATCH/PUT /orders/1
        def update
          if @order.update(order_params)
            if request.xhr?
              render json: {
                status: 'success',
                text: @order.id,
                value: @order.id
              }              
            else
              redirect_to erp_orders.edit_backend_order_path(@order), notice: t('.success')
            end
          else
            render :edit
          end
        end
    
        # DELETE /orders/1
        def destroy
          @order.destroy
          
          respond_to do |format|
            format.html { redirect_to erp_orders.backend_orders_path, notice: t('.success') }
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
              render json: Order.dataselect(params[:keyword])
            }
          end
        end
        
        # Archive /orders/archive?id=1
        def archive
          @order.archive
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Unarchive /orders/unarchive?id=1
        def unarchive
          @order.unarchive
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Draft /orders/set_draft?id=1
        def set_draft
          @order.set_draft
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
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
        
        # Archive /orders/archive_all?ids=1,2,3
        def archive_all
          @orders.archive_all
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Unarchive /orders/unarchive_all?ids=1,2,3
        def unarchive_all
          @orders.unarchive_all
          
          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end
        
        # Draft /orders/set_draft_all?ids=1,2,3
        def set_draft_all
          @orders.set_draft_all
          
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
            @order = Order.find(params[:id])
          end
          
          def set_orders
            @orders = Order.where(id: params[:ids])
          end
    
          # Only allow a trusted parameter "white list" through.
          def order_params
            params.fetch(:order, {}).permit(:order_date, :customer_id, :warehouse_id, :salesperson_id,
                                            :order_details_attributes => [ :id, :product_id, :order_id, :quantity, :price, :description, :_destroy ])
          end
      end
    end
  end
end
