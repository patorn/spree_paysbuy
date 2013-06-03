module Spree
  CheckoutController.class_eval do

    skip_before_filter :verify_authenticity_token, only: [:paysbuy_return]

    def paysbuy_return
      unless @order.payments.where(:source_type => 'Spree::PaysbuyTransaction').present?
        payment_method = PaymentMethod.where(type: "Spree::BillingIntegration::Paysbuy").last
        paysbuy_transaction = PaysbuyTransaction.new

        payment = @order.payments.create({:amount => @order.total,
                                         :source => paysbuy_transaction,
                                         :payment_method => payment_method},
                                         :without_protection => true)
        payment.started_processing!
        payment.pend!
      end

      until @order.state == "complete"
        if @order.next!
          @order.update!
          state_callback(:after)
        end
      end

      flash.notice = t(:order_processed_successfully)
      @completion_route = completion_route
      render layout: false
    end 

  end
end