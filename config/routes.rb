Erp::Orders::Engine.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    namespace :backend, module: "backend", path: "backend/orders" do
      resources :orders do
        collection do
          post 'list'
          post 'show_list'
					get 'dataselect'
					delete 'delete_all'
					put 'set_confirmed'
					put 'set_deleted'
					put 'set_confirmed_all'
					put 'set_deleted_all'
					get 'new/:type', :to => "orders#new", :as => 'new_type'
        end
      end
      resources :order_details do
				collection do
					post 'list'
          get 'order_line_form'
				end
			end
      resources :frontend_orders do
        collection do
          post 'list'
          get 'frontend_order_details'
          get 'frontend_order_line_form'
					delete 'delete_all'
					put 'set_confirm'
					put 'set_finish'
					put 'set_cancel'
					put 'set_confirm_all'
					put 'set_finish_all'
					put 'set_cancel_all'
        end
      end
    end
  end
end
