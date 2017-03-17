class SmssController < ApplicationController
  before_action :authenticate_user!

  @@data = {
      :username => "391504128",
      :password => "dCwy84Cn",
      :api_path => "http://api.rocketsms.by/simple/send",
      :cong_text => ', поздравляем Вас с днем рождения и дарим скидку 10% либо +1 месяц к рассрочке на новый заказ мебели в "Савлуков-Мебель"'
      # :cong_text => ', поздравляем Вас'
  }
  
  def index
    if is_admin?
      @today = current_day
      @tomorrow = next_day
      @users = get_users_by_query(@today) #[#<Amorail::Contact:0x007f06300daa60 @last_modified=1489640612, @linked_leads_id=["13219534"], @id=27737398, @name="", @date_create=1475581903, @responsible_user_id=475077, @linked_company_id="0", @company_name="", @phone="375292449550">]
      # @users = get_users_by_query("Пащенко") #[#<Amorail::Contact:0x007f06300daa60 @last_modified=1489640612, @linked_leads_id=["13219534"], @id=27737398, @name="", @date_create=1475581903, @responsible_user_id=475077, @linked_company_id="0", @company_name="", @phone="375292449550">]
      @future_users = get_users_by_query(@tomorrow)
      #@response = send_smss(@users[0])
    else
      redirect_to smss_denied_path
    end
  end

  def send_all
    if is_admin?
      today = current_day
      users = get_users_by_query(today)
      users.each do |user|
        response = send_smss(user)
        response["phone"] = user.phone
        @responses_by_rocket ||= []
        @responses_by_rocket << response
      end
    else
      redirect_to smss_denied_path
    end
  end

  def denied
  end

  private
    #return current day in "31.12" format for search
    def current_day
      return Time.now.strftime "%d.%m"
    end

    def next_day
      tomorrow = Time.now+60*60*24
      return tomorrow.strftime "%d.%m"
    end

    #get all users with query
    def get_users_by_query(query)
      return Amorail::Contact.find_by_query(query) #get array of objects
    end

    #get user with id
    def get_user_by_id(id)
      return Amorail::Contact.find(id) #get object
    end

    def sms_construct(name)
      name = name.split
      sms_name = name[1]+" "+name[2].to_s
      sms = sms_name + @@data[:cong_text]
      return sms
    end

    # sending sms and return response in hash {"id":8767,"status":"SENT","cost":{"credits":1,"money":100}}
    # in case of error response look like {"error":"NO_MESSAGE"}
    # QUEUED
    # поставлено в очередь для отправки
    # SENT
    # отправлено получателю
    # DELIVERED
    # доставлено получателю
    # FAILED
    # ошибка
    def send_smss(user)
      sms_text = sms_construct(user.name) #make sms with user name
      phone = user.phone
      parameters = parameters_construct(sms_text,phone) #make hash with URI parameters
      uri = URI.parse(@@data[:api_path]) #male URI
      http = Net::HTTP.new(uri.host, uri.port) #make HTTP object with uri
      request = Net::HTTP::Post.new(uri.request_uri) #POST
      request.set_form_data(parameters) #set peremeters
      #return response
      response = http.request(request) #get response
      response = JSON.parse(response.body) #parse json response
      return response
    end

    #constructor for URI parameters
    def parameters_construct(sms_text,phone) 
      query_hash ={
          :username => @@data[:username],
          :password =>  Digest::MD5.hexdigest(@@data[:password]),
          :text =>      sms_text,
          :phone =>     format_phone(phone)
      }
      return query_hash
    end

    def format_phone(phone)
      return phone.scan(/[0-9]/).join #scan all digits in array and join to string
    end

    def is_admin?
      if current_user.id == 1
        return true
      else
        return false
      end
    end
end


