module Erp
  module Orders
    module Backend
      class OrdersController < Erp::Backend::BackendController
        before_action :set_order, only: [:xlsx, :pdf, :show, :show_list, :edit, :update,
                                         :set_draft, :set_stock_checking, :set_confirmed, :set_deleted]

        # GET /orders
        def index
        end

        # POST /orders/list
        def list
          @orders = Order.search(params).paginate(:page => params[:page], :per_page => 20)

          render layout: nil
        end

        # GET /orders/1
        def show
          authorize! :read, @order
          @type = @order.sales? ? Erp::Orders::Order::TYPE_SALES_ORDER : Erp::Orders::Order::TYPE_PURCHASE_ORDER

          respond_to do |format|
            format.html
            format.pdf do
              render pdf: "show_list",
                layout: 'erp/backend/pdf'
            end
          end
        end

        # POST /orders/list
        def show_list
        end

        # GET /orders/1
        def pdf
          authorize! :print, @order
          
          @type = @order.sales? ? Erp::Orders::Order::TYPE_SALES_ORDER : Erp::Orders::Order::TYPE_PURCHASE_ORDER

          respond_to do |format|
            format.html
            format.pdf do
              if @order.order_details.count < 8
                render pdf: "#{@order.code}",
                  title: "#{@order.code}",
                  layout: 'erp/backend/pdf',
                  page_size: 'A5',
                  orientation: 'Landscape',
                  margin: {
                    top: 7,                     # default 10 (mm)
                    bottom: 2,
                    left: 7,
                    right: 7
                  }
              else
                render pdf: "#{@order.code}",
                  title: "#{@order.code}",
                  layout: 'erp/backend/pdf',
                  page_size: 'A4',
                  margin: {
                    top: 7,                     # default 10 (mm)
                    bottom: 2,
                    left: 7,
                    right: 7
                  }
              end
            end
          end
        end

        # GET /orders/new
        def new
          session[:return_to] ||= request.referer

          @order = Order.new
          @order.order_date = Time.now
          @order.warehouse_id = params.to_unsafe_hash[:warehouse] if params.to_unsafe_hash[:warehouse].present?
          @type = params[:type]

          @owner = Erp::Contacts::Contact::get_main_contact
          if @type == Erp::Orders::Order::TYPE_SALES_ORDER
            @order.supplier_id = @owner.id
          else
            @order.customer_id = @owner.id
          end
          @order.payment_for = Erp::Orders::Order::PAYMENT_FOR_ORDER

          # Import details list from stocking importing page
          if params[:products].present?
            params.to_unsafe_hash[:products].each do |row|
              product = Erp::Products::Product.find(row[0])

              purchase_price = product.get_purchase_price(quantity: row[1])

              @order.order_details.build(
                product_id: product.id,
                price: purchase_price.present? ? purchase_price.price : 0.0,
                quantity: row[1]
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

          session[:return_to] ||= request.referer

          @type = @order.sales? ? Erp::Orders::Order::TYPE_SALES_ORDER : Erp::Orders::Order::TYPE_PURCHASE_ORDER
        end

        # POST /orders
        def create
          @order = Order.new(order_params)
          @order.creator = current_user

          if @order.save
            # update cache
            @order.update_cache_delivery_status

            if @order.sales?
              if params.to_unsafe_hash[:act_save_with_default].present?
                @order.set_draft
              elsif params.to_unsafe_hash[:act_save_with_checking].present?
                @order.set_stock_checking
              end
            else
              @order.set_draft
            end

            if request.xhr?
              render json: {
                status: 'success',
                text: @order.code,
                value: @order.id
              }
            else
              if @order.sales?
                redirect_to session.delete(:return_to)
                # redirect_to erp_sales.backend_sales_orders_path, notice: t('.success')
              elsif @order.purchase?
                redirect_to session.delete(:return_to)
                # redirect_to erp_purchase.backend_purchase_orders_path, notice: t('.success')
              end
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
          authorize! :update, @order

          if @order.sales?
            if params.to_unsafe_hash[:act_save_with_default].present?
              if @order.is_items_change?(params.to_unsafe_hash[:order]["order_details_attributes"]) == true
                #@order.set_draft
              end
            elsif params.to_unsafe_hash[:act_save_with_checking].present?
              @order.set_stock_checking
            end
          else
            #@order.set_draft
          end

          if @order.update(order_params)
            # update cache
            @order.update_cache_delivery_status

            if request.xhr?
              render json: {
                status: 'success',
                text: @order.code,
                value: @order.id
              }
            else
              if @order.sales?
                redirect_to session.delete(:return_to)
                # redirect_to erp_sales.backend_sales_orders_path, notice: t('.success')
              elsif @order.purchase?
                redirect_to session.delete(:return_to)
                # redirect_to erp_purchase.backend_purchase_orders_path, notice: t('.success')
              end
            end
          else
            render :edit
          end
        end

        # dataselect /orders
        def dataselect
          respond_to do |format|
            format.json {
              render json: Order.dataselect(params[:keyword], params.to_unsafe_hash)
            }
          end
        end

        # Stock checking /orders/set_stock_checking?id=1
        def set_stock_checking
          authorize! :set_stock_checking, @order
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

        def xlsx
          respond_to do |format|
            format.xlsx {
              response.headers['Content-Disposition'] = "attachment; filename='Don hang #{@order.code}.xlsx'"
            }
          end
        end
        
        def ajax_employee_field
          @customer = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @supplier = Erp::Contacts::Contact.where(id: params[:datas][1]).first
          
          @employee = Erp::User.new
          
          if params[:employee_id].present?
            @employee = Erp::User.find(params[:employee_id])
          else
            if @customer.present? and @customer.salesperson_id.present?
              @employee = Erp::User.find(@customer.salesperson_id)
            end
            
            if @supplier.present? and @supplier.salesperson_id.present?
              @employee = Erp::User.find(@supplier.salesperson_id)
            end
          end
          
          render layout: false
        end

        private
          # Use callbacks to share common setup or constraints between actions.
          def set_order
            @order = Order.find(params[:id])
          end

          # Only allow a trusted parameter "white list" through.
          def order_params
            params.fetch(:order, {}).permit(:patient_state_id, :is_new_patient, :patient_id, :doctor_id, :hospital_id, :code, :order_date, :customer_id, :supplier_id, :employee_id, :warehouse_id, :note, :tax_id, :payment_for,
                                            :order_details_attributes => [ :id, :product_id, :order_id, :quantity, :price, :discount, :shipping_fee,
                                                                          :commission, :customer_commission, :description, :serials, :eye_position,
                                                                          :request_product_id, :must_same_code, :must_same_diameter, :_destroy ])
          end
      end
    end
  end
end
