Spree::Core::Engine.routes.draw do
  # Add your extension routes here

  resources :orders do
    resource :checkout, :controller => 'checkout' do
      member do
        get :paysbuy_return
        post :paysbuy_return
      end
    end
  end

  match '/paysbuy_callbacks/notify' => 'paysbuy_callbacks#notify', :via => :post, :as => :paysbuy_notify
end
