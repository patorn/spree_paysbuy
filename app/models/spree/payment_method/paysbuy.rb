class Spree::PaymentMethod::Paysbuy < Spree::PaymentMethod
  include HTTParty

  preference :domain, :string
  preference :username, :string
  preference :psbid, :string 
  preference :securecode, :string
  preference :test_mode, :boolean
  
  attr_accessible :preferred_domain, :preferred_username, :preferred_psbid, :preferred_securecode, :preferred_test_mode

  def self.verify_encrypt(input, encrypted)
    self.encrypt(input) == encrypted
  end

  def self.encrypt(data)
    Digest::HMAC.hexdigest(data, "SmartSoftAsia69", Digest::SHA2)
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
        psbID: self.preferred_psbid, 
        username: self.preferred_username, 
        secureCode: self.preferred_securecode,
        inv: args_options[:invoice],
        itm: '1',        
        amt: args_options[:amount],
        paypal_amt: '',
        curr_type: 'TH',
        com: '',
        method: 1,
        language: args_options[:lang],
        resp_front_url: "#{self.preferred_domain}/orders/#{args_options[:order_id]}/checkout/paysbuy_return",
        resp_back_url: "#{self.preferred_domain}/paysbuy_callbacks/notify?encryted_order_number=#{self.class.encrypt args_options[:invoice]}",
        opt_fix_redirect: 1,
        opt_fix_method: '',
        opt_name: args_options[:name],
        opt_email: args_options[:email],
        opt_mobile: '',
        opt_address: "",
        opt_detail: ""
      }
    }

    result = self.class.post(base_uri + uri, options)
    attempt = 0

    # if have got an unexpected result, try to get the correct result again
    # from API document, return result should start with '00'
    # if not start with '00' should try again (then, try 5 times)
    while(!(result.parsed_response["string"] =~ /^00/) && 
      (attempt <= 5)) do

      result = self.class.post(base_uri + uri, options)
      attempt += 1
    end

    result.parsed_response["string"].gsub(/^00/, "")
  end

  def service_uri(*args)
    "/paynowiframe.aspx?refid=#{request_token(*args)}"
  end

  def service_url(*args)
    options = args.extract_options!
    URI::join( base_uri, service_uri(options)).to_s
  end

  def verify
    puts self.preferred_psbid
  end

  def base_uri
    if preferred_test_mode == true
      'http://demo.paysbuy.com'
    else
      'https://www.paysbuy.com'
    end
  end

end