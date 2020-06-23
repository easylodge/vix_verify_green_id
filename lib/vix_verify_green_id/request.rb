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

  def build_address(address)
    {
        :'streetNumber' => (address[:level]),
        :'streetName' => (address[:street]),
        :'streetType' => (address[:street_type]),
        :'suburb' => (address[:suburb]),
        :'state' => (address[:state]),
        :'postcode' => (address[:postcode]),
        :'country' => (address[:country])
    }
  end

  def register_verification
    name = {
       :"honorific" => self.entity[:title].to_s,
       :"givenName" => self.entity[:first_given_name].to_s,
       :"middleNames" => self.entity[:other_given_name].to_s,
       :"surname" => self.entity[:family_name].to_s
    }

    current_address = build_address(self.entity[:current_address])

    previous_address = build_address(self.entity[:previous_address])

    dob = self.entity[:date_of_birth].to_date

    date_of_birth = {
      :"day" => dob.day,
      :"month" => dob.month,
      :"year" => dob.year
    }

    { :"accountId" => account_id,
      :"password" => password,
      :"ruleId" => "default",
      :"name" => name,
      :"email" => self.entity[:email_address].to_s,
      :"currentResidentialAddress" => current_address,
      :"previousResidentialAddress" => previous_address,
      :"dob" => date_of_birth,
      :"homePhone" => self.entity[:home_phone_number].to_s,
      :"workPhone" => self.entity[:work_phone_number].to_s,
      :"mobilePhone" => self.entity[:mobile_phone_number].to_s,
      :"generateVerificationToken" => true
    }
  end

  def set_fields(source)
    { :'accountId' => account_id, :'password' => password ,
      :'verificationId' => self.registration_response.verification_id, :'sourceId' => source[:key],
      :'inputFields' => source[:values]
    }
  end

  def license_key_prefix(state)
    "#{state.downcase}regodvs"
  end

  def source_field_values
    fields = []
    state = (self.entity[:current_address][:state])
    prefix = license_key_prefix(state)
    given_name = self.entity[:first_given_name].to_s
    middle_name = self.entity[:other_given_name].to_s
    surname = self.entity[:family_name].to_s
    dob = self.entity[:date_of_birth]

    license_details = [
        { name: "greenid_#{prefix}_number", value: self.entity[:drivers_licence_number] },
        { name: "greenid_#{prefix}_givenname", value: given_name},
        { name: "greenid_#{prefix}_middlename", value: middle_name },
        { name: "greenid_#{prefix}_surname", value: surname },
        { name: "greenid_#{prefix}_dob", value: dob },
        { name: "greenid_#{prefix}_tandc", value: 'on' }
    ]
    fields << { key: prefix, values: license_details } if self.entity[:drivers_licence_number].presence

    passport_details = [
        { name: 'greenid_passportdvs_number', value: self.entity[:passport_number] },
        { name: 'greenid_passportdvs_givenname', value: given_name},
        { name: 'greenid_passportdvs_middlename', value: middle_name },
        { name: 'greenid_passportdvs_surname', value: surname },
        { name: 'greenid_passportdvs_dob', value: dob },
        { name: 'greenid_passportdvs_tandc', value: 'on' }
    ]
    fields << { key: "passportdvs", values: passport_details } if self.entity[:passport_number].presence

    medicare_details = [
        { name: 'greenid_medicaredvs_number', value: (self.entity[:medicare_card_number]) },
        { name: 'greenid_medicaredvs_nameOnCard', value: "#{surname} #{middle_name} #{given_name}" },
        { name: 'greenid_medicaredvs_cardColour', value: (self.entity[:medicare_card_color]) },
        { name: 'greenid_medicaredvs_individualReferenceNumber', value: (self.entity[:medicare_reference_number]) },
        { name: 'greenid_medicaredvs_expiry', value: (self.entity[:medicare_card_expiry]) },
        { name: 'greenid_medicaredvs_tandc', value: 'on' }
    ]
    fields << { key: "medicaredvs", values: medicare_details } if self.entity[:medicare_card_number].presence
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

  def post
    self.to_soap
    if self.soap
      rv = HTTParty.post(self.access[:url], body: self.soap, headers: {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'})
      rr = self.create_registration_response!(code: rv.code, success: rv.success?, request_id: self.id, xml: rv.body, headers: rv.headers)

      if rr.result_verification_token
        rr.update_columns(verification_token: rr.result_verification_token, verification_id: rr.result_verification_id)
      end

      return rv unless source_field_values.any?

      source_field_values.each do |source|
        post_source(source)
      end
    else
      "No soap envelope to post! - run to_soap"
    end
  end

  def post_source(source)
    HTTParty.post(self.access[:url], body: self.add_envelope(self.source_xml_body(source)), headers: {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'})
  end
end
