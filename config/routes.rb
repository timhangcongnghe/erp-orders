Erp::Orders::Engine.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    namespace :backend, module: "backend", path: "backend/orders" do
      resources :orders do
        collection do
          post 'list'
					get 'dataselect'
					put 'archive'
					put 'unarchive'
					delete 'delete_all'
					put 'archive_all'
					put 'unarchive_all'
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