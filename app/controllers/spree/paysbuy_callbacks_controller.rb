module Spree
  class PaysbuyCallbacksController < Spree::BaseController

    skip_before_filter :verify_authenticity_token

    # Receive a direct notification from the gateway
    def notify
      encrypted_num = params[:encryted_order_number]
      result = params[:result]
      result_code = (params[:result] || "")[0,2]
      order_number = (params[:result] || "")[2,10]
      verified = Spree::PaymentMethod::Paysbuy.verify_encrypt(order_number, encrypted_num)

      @order ||= Spree::Order.find_by_number!(order_number)
      
      # result_code '00' is success
      if result_code == "00" && verified && check_same_amount?(@order, params[:amt])
        
        payment_method = PaymentMethod.where(type: "Spree::PaymentMethod::Paysbuy").last
        payment = @order.payments.where(:state => "pending", 
                                        :payment_method_id => payment_method).first
        paysbuy_transaction = PaysbuyTransaction.create_from_postback params

        if payment
          payment.source = paysbuy_transaction
          payment.save
        else
          payment = @order.payments.create(:amount => @order.total,
                                           :source => paysbuy_transaction,
                                           :payment_method => payment_method)
        end

        payment.started_processing!

        unless payment_method == "06"
          # any payment methods except counter service (06)
          payment.complete!  
        else
          # counter service
          if confirm_cs == "true"
            payment.complete! 
          else
            payment.failure!
            log_failed_payment(@order, 
                params[:result],
                verified, 
                check_same_amount?(@order, params[:amt])
              )
          end
        end
        log_completed_payment(@order)
      else
        log_failed_order(params[:result])
        payment.failure!
      end

      render :text => ""
    end

    def log_completed_payment(order)
      Rails.logger.info("--------------SUCCESS-----------------")
      Rails.logger.info("order: #{order.number} /#{order.total} baht payment success")
      Rails.logger.info("--------------------------------------")
    end

    def log_failed_payment(order, result, encrpyted_check, amount_check)
      Rails.logger.info("---------------FAILED-----------------")
      Rails.logger.info("order: #{order.number} payment failed ")
      Rails.logger.info("RESULTCODE: #{result}")
      Rails.logger.info("ENCRYTED CHECK: #{encrpyted_check}")
      Rails.logger.info("AMOUNT: #{amount_check}")
      Rails.logger.info("--------------------------------------")
    end

    def log_failed_order(result)
      Rails.logger.info("---------------FAILED-----------------")
      Rails.logger.info("UNKNOWN ORDER NUMBER ")
      Rails.logger.info("RESULTCODE: #{result}")
      Rails.logger.info("--------------------------------------")
    end

    def check_same_amount?(order, amount)
      order.amount.to_f == amount.to_f
    end  

  end
end