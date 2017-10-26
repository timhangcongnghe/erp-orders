module Erp
  module Orders
    module Backend
      class OrderDetailsController < Erp::Backend::BackendController
        before_action :set_order_detail, only: [:show, :edit, :update, :destroy]

        # GET /order_details
        def index
          @order_details = OrderDetail.all
        end

        # POST /order_details/list
        def list
          @order_details = OrderDetail.search(params).paginate(:page => params[:page], :per_page => 5)

          render layout: nil
        end

        # GET /order_details/new
        def new
          @order_detail = OrderDetail.new
        end

        # GET /order_details/1/edit
        def edit
        end

        # POST /order_details
        def create
          @order_detail = OrderDetail.new(order_detail_params)

          if @order_detail.save
            if request.xhr?
              render json: {
                status: 'success',
                text: @order_detail.name,
                value: @order_detail.id
              }
            else
              redirect_to erp_orders.edit_backend_order_detail_path(@order_detail), notice: t('.success')
            end
          else
            render :new
          end
        end

        # PATCH/PUT /order_details/1
        def update
          if @order_detail.update(order_detail_params)
            if request.xhr?
              render json: {
                status: 'success',
                text: @order_detail.name,
                value: @order_detail.id
              }
            else
              redirect_to erp_orders.edit_backend_order_detail_path(@order_detail), notice: t('.success')
            end
          else
            render :edit
          end
        end

        # DELETE /order_details/1
        def destroy
          @order_detail.destroy
          redirect_to order_details_url, notice: 'Order detail was successfully destroyed.'
        end

        def order_line_form
          @order_detail = OrderDetail.new
          @order_detail.product_id = params[:add_value]
          @order_detail.price = @order_detail.product_price

          render partial: params[:partial], locals: {
            order_detail: @order_detail,
            uid: helpers.unique_id()
          }
        end
        
        def ajax_customer_commission_field
          @customer = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @product = Erp::Products::Product.where(id: params[:datas][1]).first
          @uid = params[:datas][2]
          if params[:customer_commission].present? and @customer.id == params[:customer_id].to_i
            @customer_commission = params[:customer_commission]
          else
             if !params[:order_detail_id].present?
               @customer_commission = @customer.get_customer_commission_rate_by_product(@product)
             else
               @customer_commission = ''
             end
          end
          render layout: false
        end

        private
          # Use callbacks to share common setup or constraints between actions.
          def set_order_detail
            @order_detail = OrderDetail.find(params[:id])
          end

          # Only allow a trusted parameter "white list" through.
          def order_detail_params
            params.fetch(:order_detail, {}).permit(:product_id, :order_id, :quantity, :price, :discount, :shipping_fee, :description)
          end
      end
    end
  end
end
