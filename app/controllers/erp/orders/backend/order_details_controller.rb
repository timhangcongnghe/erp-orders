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
          @order_detail.price = @order_detail.get_show_price

          @order_detail.order = Erp::Orders::Order.new

          if params[:type] == Erp::Orders::Order::TYPE_SALES_ORDER
            @order_detail.order.supplier_id = Erp::Contacts::Contact::get_main_contact
          else
            @order_detail.order.supplier_id = Erp::Contacts::Contact::get_main_contact
          end
          
          # warehouse
          if params[:form].present? and params[:form][:order].present? and params[:form][:order][:warehouse_id].present?
            @order_detail.warehouse_id = params[:form][:order][:warehouse_id]
          end

          render partial: params[:partial], locals: {
            order_detail: @order_detail,
            uid: helpers.unique_id()
          }
        end

        def ajax_default_sales_price_info
          @customer = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @product = Erp::Products::Product.where(id: params[:datas][1]).first
          @qty = params[:datas][2].to_i
          
          # get product default price
          @customer_price = @product.get_default_sales_price(
            contact_id: (@customer.present? ? @customer.id : nil),
            quantity: @qty
          )
          
          @uid = params[:datas][4]
        end

        def ajax_default_purchase_price_info
          @supplier = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @product = Erp::Products::Product.where(id: params[:datas][1]).first
          @qty = params[:datas][2].to_i
          
          # get product default price
          @supplier_price = @product.get_default_purchase_price(
            contact_id: (@supplier.present? ? @supplier.id : nil),
            quantity: @qty
          )
          
          @uid = params[:datas][4]
        end

        def ajax_default_customer_commission_info
          @customer = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @product = Erp::Products::Product.where(id: params[:datas][1]).first
          @qty = params[:datas][2].gsub(/\,/, '').to_i
          @price = params[:datas][3].gsub(/\,/, '').to_f
          @discount = params[:datas][4].gsub(/\,/, '').to_f
          @uid = params[:datas][5]
          #@price = params[:price].present? ? params[:price].to_f : 0.0
          #@qty = params[:quantity].present? ? params[:quantity].to_f : 0

          @customer_commission_amount = 0

          if @customer.present?
            @customer_commission = @customer.get_customer_commission_rate_by_product(@product)
            if @customer_commission.present?
              if @customer_commission.price.to_f > 0
                  @customer_commission_amount = @customer_commission.price
              elsif @customer_commission.rate.to_f > 0
                  @customer_commission_amount = ((@customer_commission.rate*(@price*@qty-@discount))/100).to_f
              end
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
