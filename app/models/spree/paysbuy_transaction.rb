module Spree
  class PaysbuyTransaction < ActiveRecord::Base
    has_many :payments, :as => :source
    attr_accessible :ap_code, :result, :amount, :fee, :method, :confirm_cs

    def actions
      []
    end

    def self.create_from_postback(params)
       PaysbuyTransaction.create(:ap_code => params[:apCode],
                               :result => params[:result],
                               :amount => params[:amt],
                               :fee => params[:fee],
                               :method => params[:method],
                               :confirm_cs => params[:confirm_cs]
                              )
    end

  end
end
