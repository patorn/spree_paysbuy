module Spree
  class PaysbuyTransaction < ActiveRecord::Base
    has_many :payments, :as => :source

    def actions
      []
    end

    def self.create_from_postback(params)
       PaysbuyTransaction.create(:ap_code => params[:apcode],
                               :result => params[:result],
                               :amount => params[:amt],
                               :fee => params[:fee],
                               :payment_method => params[:method],
                               :confirm_cs => params[:confirm_cs]
                              )
    end

  end
end
