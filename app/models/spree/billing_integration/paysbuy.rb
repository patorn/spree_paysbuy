class Spree::BillingIntegration::Paysbuy < Spree::BillingIntegration
  include HTTParty

  # Set up payment environment
  if Rails.env == 'production'
    base_uri 'http://demo.paysbuy.com'
    PSBID = "8303545188"
    USERNAME = "demo@paysbuy.com"
    SECURECODE = "1586093A8F80CBB5003001B42F0EEB7C"    
    DOMAIN = "http://localhost:3000"
  else
    base_uri 'http://demo.paysbuy.com'
    PSBID = "8303545188"
    USERNAME = "demo@paysbuy.com"
    SECURECODE = "1586093A8F80CBB5003001B42F0EEB7C"    
    DOMAIN = "http://localhost:3000"
  end

  def provider_class
    ActiveMerchant::Billing::Integrations::Paysbuy
  end

  # required input
  #
  # invoice:  ref
  # amount:  1000
  # name:
  # email:
  # lang:
  #
  def request_token(*args)
    args_options = args.extract_options!
    uri = '/api_paynow/api_paynow.asmx/api_paynow_authentication_new'

    options ={
      body: {
        psbID: PSBID, 
        username: USERNAME, 
        secureCode: SECURECODE,
        inv: args_options[:invoice],
        itm: '1',        
        amt: args_options[:amount],
        paypal_amt: '',
        curr_type: 'TH',
        com: '',
        method: 1,
        language: args_options[:lang],
        resp_front_url: "#{DOMAIN}/orders/#{args_options[:order_id]}/checkout/paysbuy_return",
        resp_back_url: "#{DOMAIN}/paysbuy_callbacks/notify?encryted_order_number=#{encrypt args_options[:invoice]}",
        opt_fix_redirect: 1,
        opt_fix_method: '',
        opt_name: args_options[:name],
        opt_email: args_options[:email],
        opt_mobile: '',
        opt_address: "",
        opt_detail: ""
      }
    }

    result = self.class.post(uri, options)
    attempt = 0

    # if have got an unexpected result, try to get the correct result again
    # from API document, return result should start with '00'
    # if not start with '00' should try again (then, try 5 times)
    while(!(result.parsed_response["string"] =~ /^00/) && 
      (attempt <= 5)) do

      result = self.class.post(uri, options)
      attempt += 1
    end

    result.parsed_response["string"].gsub(/^00/, "")
  end

  def service_uri(*args)
    "/paynowiframe.aspx?refid=#{request_token(*args)}"
  end

  def service_url(*args)
    options = args.extract_options!

    URI::join( self.class.base_uri, service_uri(options)).to_s
  end

  def verify
    puts PSBID
  end

  def encrypt(data)
    Digest::HMAC.hexdigest(data, "SmartSoftAsia69", Digest::SHA2)
  end

  def self.verify_encrypt(input, encrypted)
    encrypt(input) == encrypted
  end

end