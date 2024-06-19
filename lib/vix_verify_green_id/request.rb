class VixVerifyGreenId::Request < ActiveRecord::Base
  self.table_name = "vix_verify_green_id_requests"
  has_one :registration_response, dependent: :destroy, inverse_of: :request
  has_one :response, dependent: :destroy, inverse_of: :request
  serialize :access
  serialize :entity
  serialize :enquiry

  validates :ref_id, presence: true
  validates :access, presence: true
  validates :entity, presence: true

  def account_id
    self.access[:access_code]
  end

  def password
    self.access[:password]
  end

  def req_headers
    {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'}
  end

  def to_soap
    if self.entity
      self.to_xml_body
      self.soap = self.add_envelope(self.xml)
    else
      "No entity details - set your entity hash"
    end
  end

  def to_xml_body
    doc = self.to_dom("dyn:registerVerification", self.register_verification).to_xml
    self.xml = doc.gsub('<?xml version="1.0"?>','')
  end

  def to_dom(node, data, attrs={})
    doc = Nokogiri::XML::Builder.new do |builder|
      if data.is_a?(Hash) && data.keys.sort == [:attributes, :value]
        attrs.merge!(data[:attributes])
        data = data[:value]
      end

      if data.is_a? Hash
        builder.send(node, attrs) do
          data.keys.each do |k|
            builder << to_dom(k, data[k]).root.to_xml
          end
        end
      elsif data.is_a?(Array)
        builder.send(node, attrs) do
          data.each do |d|
            builder << to_dom('input', d).root.to_xml
          end
        end
      else
        builder.send(node, data, attrs)
      end
    end
    doc.doc
  end

  # This module includes methods for verifying GreenID requests. When creating a GreenID request, the entity_hash method is used to format the user's personal information. The formatted_address method is used to format the user's address information. The following are the requirements for the address fields in Australia:
  # - propertyName: No (less than 256 characters)
  # - flatNumber: No (less than 256 characters)
  # - streetNumber: Yes (less than 256 characters)
  # - streetName: Yes (less than 256 characters)
  # - streetType: No (if present, must be one of the street types listed at AU Street Types, otherwise it will be discarded)
  # - suburb: Yes (less than 256 characters)
  # - postcode: Yes (must be 4 digits)
  # - state: Yes (must be one of the following: ACT, NSW, NT, QLD, SA, TAS, VIC, WA)
  # - country: Yes (must be AU)
  def build_address(address)
    {
      country: address[:country],
      postcode: address[:postcode],
      state: address[:state],
      streetName: address[:street],
      streetNumber: address[:street_number],
      streetType: address[:street_type],
      suburb: address[:suburb]
    }
  end

  # This section of code defines the structure of a GreenID request. It includes the following fields:
  # - accountId: String. Yes. The account ID provided by GreenID.
  # - password: String. Yes. The password provided by GreenID.
  # - ruleId: String. No. The rule ID provided by GreenID. If not provided, the default rule will be used.
  # - name: Hash. Yes. The person’s name. See the name_hash method for more details.
  # - email: String. No. The person’s email address.
  # - dob: Hash. Yes. The person’s date of birth. See the dob_hash method for more details.
  # - homePhone: String. No. If present, must be 10 digits only.
  # - workPhone: String. No. If present, must be 10 digits only.
  # - mobilePhone: String. No. If present, must be 10 digits only.
  # - currentResidentialAddress: Hash. No. The person’s current residential address. See the build_address method for more details.
  # - previousResidentialAddress: Hash. No. The person’s previous residential address. See the build_address method for more details.
  def register_verification
    info = {
      accountId: account_id,
      password: password,
      ruleId: "default",
      name: name_hash(),
      email: entity[:email_address].to_s,
      dob: dob_hash(),
      homePhone: entity[:home_phone].to_s,
      workPhone: entity[:work_phone].to_s,
      mobilePhone: entity[:mobile_phone].to_s,
      generateVerificationToken: true
    }

    if entity[:current_address].present?
      info[:currentResidentialAddress] = build_address(entity[:current_address])
    end

    if entity[:previous_address].present?
      info[:previousResidentialAddress] = build_address(entity[:previous_address])
    end

    info
  end

  # This section of code defines the structure of a person's name. It includes the following fields:
  # - honorific: String. No. The honorific component of a person’s name, e.g., “Mr”, “Miss”, etc. Max 255 characters.
  # - givenName: String. Yes. A person’s given name. Cannot be null. Cannot be the empty string. Max 255 characters.
  # - middleNames: String. No. A person’s middle names. Note that there can be multiple names. Max 255 characters.
  # - surname: String. Yes. A person’s surname or last name. Cannot be null. Cannot be the empty string. Max 255 characters.
  def name_hash()
    {
      honorific: entity[:honorific].to_s,
      givenName: entity[:given_name].to_s,
      middleNames: entity[:middle_names].to_s,
      surname: entity[:surname].to_s
    }
  end

  # This method returns a hash containing the day, month, and year components of a date of birth.
  # - day: int. The day component of a date of birth.
  # - month: int. The month component of a date of birth.
  # - year: int. The full year component of a date of birth, for example 1975, i.e. not 75.
  def dob_hash()
    dob = (Date.parse(entity[:date_of_birth]) rescue nil)

    {
      day: dob&.day,
      month: dob&.month,
      year: dob&.year
    }
  end

  def set_fields(source)
    {
      accountId: account_id,
      password: password ,
      verificationId: self.registration_response.verification_id,
      sourceId: source[:key],
      inputFields: source[:values]
    }
  end

  def license_key_prefix(state)
    "#{state.downcase}regodvs" rescue nil
  end

  def source_field_values
    fields = []

    if entity[:drivers_licence_number].present?
      prefix = license_key_prefix(entity[:drivers_licence_state_code])

      fields << {
        key: prefix,
        values: [
          { name: "greenid_#{prefix}_number", value: entity[:drivers_licence_number] },
          { name: "greenid_#{prefix}_cardnumber", value: entity[:drivers_licence_card_number] },
          { name: "greenid_#{prefix}_givenname", value: entity[:given_name].to_s },
          { name: "greenid_#{prefix}_middlenames", value: entity[:middle_names].to_s },
          { name: "greenid_#{prefix}_surname", value: entity[:surname].to_s },
          { name: "greenid_#{prefix}_dob", value: entity[:date_of_birth] },
          { name: "greenid_#{prefix}_tandc", value: 'on' }
        ]
      }
    end

    if entity[:passport_number].present?
      fields << {
        key: "passportdvs",
        values: [
          { name: 'greenid_passportdvs_number', value: entity[:passport_number] },
          { name: 'greenid_passportdvs_givenname', value: entity[:given_name].to_s},
          { name: 'greenid_passportdvs_middlename', value: entity[:middle_names].to_s },
          { name: 'greenid_passportdvs_surname', value: entity[:surname].to_s },
          { name: 'greenid_passportdvs_dob', value: entity[:date_of_birth] },
          { name: 'greenid_passportdvs_tandc', value: 'on' }
        ]
      }
    end

    if self.entity[:medicare_card_number].present?
      medicare_combined_name = if entity[:middle_names].to_s.length > 0
        [entity[:given_name].to_s, entity[:middle_names].to_s.first, entity[:surname].to_s].join(' ')
      else
        [entity[:given_name].to_s, entity[:surname].to_s].join(' ')
      end

      fields << {
        key: "medicaredvs",
        values: [
          { name: 'greenid_medicaredvs_middleInitialOnCard', value: entity[:medicare_middle_initial_on_card] },
          { name: 'greenid_medicaredvs_number', value: entity[:medicare_card_number] },
          { name: 'greenid_medicaredvs_nameOnCard', value: medicare_combined_name },
          { name: 'greenid_medicaredvs_cardColour', value: entity[:medicare_card_color] },
          { name: 'greenid_medicaredvs_individualReferenceNumber', value: entity[:medicare_reference_number] },
          { name: 'greenid_medicaredvs_expiry', value: entity[:medicare_card_expiry] },
          { name: 'greenid_medicaredvs_tandc', value: 'on' }
        ]
      }
    end

    fields
  end

  def source_xml_body(source)
    doc = self.to_dom("dyn:setFields", self.set_fields(source)).to_xml
    doc.gsub('<?xml version="1.0"?>','')
  end


  def mandatory_values_empty?(values_hash)
    values_hash.values.any? {|val| val.nil? || val.to_s.empty?}
  end

  def add_envelope(xml_message)
    "<soapenv:Envelope
      xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
      xmlns:dyn=\"http://dynamicform.services.registrations.edentiti.com/\">
      <soapenv:Header/>
      <soapenv:Body>#{xml_message}</soapenv:Body>
    </soapenv:Envelope>"
  end

  def verification_result_body(verification_id)
    body = {
      accountId: account_id,
      password: password,
      verificationId: verification_id
    }

    doc = self.to_dom("dyn:getVerificationResult", body).to_xml
    doc.gsub('<?xml version="1.0"?>','')
  end

  def post
    self.to_soap

    if self.soap
      local_request = HTTParty.post(self.access[:url], body: self.soap, headers: req_headers)
      local_response = self.registration_response || self.build_registration_response()

      local_response.update(code: local_request.code,
        success: local_request.success?,
        request_id: self.id,
        xml: local_request.body,
        headers: local_request.headers
      )

      if local_response.result_verification_id
        local_response.update_columns(verification_id: local_response.result_verification_id)
      end

      if local_response.result_verification_token
        local_response.update_columns(verification_token: local_response.result_verification_token)
      end

      return local_request unless local_request.success? && source_field_values.any?

      source_field_values.each do |source|
        post_source(source)
      end

      verification_request_xml = verification_result_body(local_response.result_verification_id)
      get_verification_result(verification_request_xml)
    else
      "No soap envelope to post! - run to_soap"
    end
  end

  def current_status
    body = verification_result_body(response.result_verification_id)
    request = get_verification_result(body)

    return unless request.success?

    begin
      request.as_json["Envelope"]["Body"]["getVerificationResultResponse"]["return"]["verificationResult"]["overallVerificationStatus"]
    rescue
      nil
    end
  end

  def get_verification_result(verification_result_body)
    HTTParty.post(self.access[:url], body: add_envelope(verification_result_body), headers: req_headers)
  end

  def post_source(source)
    binding.pry
    res = HTTParty.post(self.access[:url], body: add_envelope(source_xml_body(source)), headers: req_headers)
  end
end
