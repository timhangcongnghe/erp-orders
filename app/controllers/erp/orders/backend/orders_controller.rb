module Erp
  module Orders
    module Backend
      class OrdersController < Erp::Backend::BackendController
        before_action :set_order, only: [:show, :show_list, :edit, :update, :destroy,
                                         :set_stock_checking, :set_stock_checked, :set_stock_approved, :set_confirmed, :set_deleted]
        before_action :set_orders, only: [:delete_all, :set_confirmed_all, :set_deleted_all]

        # GET /orders
        def index
        end

        # POST /orders/list
        def list
          @orders = Order.search(params).paginate(:page => params[:page], :per_page => 10)

          render layout: nil
        end

        # GET /orders/1
        def show
          authorize! :read, @order
          @type = @order.sales? ? Erp::Orders::Order::TYPE_SALES_ORDER : Erp::Orders::Order::TYPE_PURCHASE_ORDER
        end

        # POST /orders/list
        def show_list

        end

        # GET /orders/new
        def new
          @order = Order.new
          @order.order_date = Time.now
          @order.employee = current_user
          @type = params[:type]
          @owner = Erp::Contacts::Contact::get_main_contact
          if @type == Erp::Orders::Order::TYPE_SALES_ORDER
            @order.supplier_id = @owner.id
          else
            @order.customer_id = @owner.id
          end

          # Import details list from stocking importing page
          if params[:side_quantity].present?
            ids = Erp::Products::Product.pluck(:id).sample(rand(90..250))
            @products = Erp::Products::Product.where(id: ids).order(:code)

            @products.each do |product|
              area_type = params[:area].present? ? params[:area] : ['area_side','area_central'].sample
              total_quantity = area_type == 'area_central' ? params[:central_quantity].to_f : params[:side_quantity].to_f

              @order.order_details.build(
                product_id: product.id,
                # product_name: product.code + ' ' + product.get_diameter + ' ' + product.category_name
                price: product.price,
                quantity: total_quantity
              )
            end
          end

          if request.xhr?
            render '_form', layout: nil, locals: {order: @order}
          end
        end

        # GET /orders/1/edit
        def edit
          authorize! :update, @order
          @type = @order.sales? ? Erp::Orders::Order::TYPE_SALES_ORDER : Erp::Orders::Order::TYPE_PURCHASE_ORDER
        end

        # POST /orders
        def create
          @order = Order.new(order_params)
          @order.creator = current_user
          @order.status = Erp::Orders::Order::STATUS_DRAFT

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
              render json: Order.dataselect(params[:keyword], params)
            }
          end
        end

        # Stock checking /orders/set_stock_checking?id=1
        def set_stock_checking
          #authorize! :confirm, @order
          @order.set_stock_checking

          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end

        # Stock checked /orders/set_stock_checked?id=1
        def set_stock_checked
          #authorize! :confirm, @order
          @order.set_stock_checked

          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end

        # Stock approved /orders/set_stock_approved?id=1
        def set_stock_approved
          #authorize! :confirm, @order
          @order.set_stock_approved

          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end

        # Confirmed /orders/set_confirmed?id=1
        def set_confirmed
          authorize! :confirm, @order
          @order.set_confirmed

          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end

        # Deleted /orders/set_deleted?id=1
        def set_deleted
          authorize! :delete, @order
          @order.set_deleted

          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end

        # Confirmed /orders/set_confirmed_all?ids=1,2,3
        def set_confirmed_all
          authorize! :confirm, @order
          @orders.set_confirmed_all

          respond_to do |format|
          format.json {
            render json: {
            'message': t('.success'),
            'type': 'success'
            }
          }
          end
        end

        # Deleted /orders/set_deleted_all?ids=1,2,3
        def set_deleted_all
          authorize! :delete, @order
          @orders.set_deleted_all

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
            params.fetch(:order, {}).permit(:code, :order_date, :customer_id, :supplier_id, :employee_id, :warehouse_id, :note, :tax_id,
                                            :order_details_attributes => [ :id, :product_id, :order_id, :quantity, :price, :discount, :shipping_fee, :description, :_destroy ])
          end
      end
    end
  end
end
