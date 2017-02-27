Erp::Orders::Engine.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    namespace :backend, module: "backend", path: "backend/orders" do
      resources :orders do
        collection do
          post 'list'
					get 'dataselect'
					delete 'delete_all'
					put 'set_confirm'
					put 'set_cancel'
					put 'set_confirm_all'
					put 'set_cancel_all'
        end
      end
      resources :order_details do
				collection do
					post 'list'
          get 'order_line_form'
				end
			end
    end
  end
end