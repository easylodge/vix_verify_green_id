class VixVerifyGreenId::Request < ActiveRecord::Base
  self.table_name = "vix_verify_green_id_requests"
  has_one :response, dependent: :destroy, inverse_of: :request
  serialize :access
  serialize :entity
  serialize :enquiry

  validates :ref_id, presence: true
  validates :access, presence: true
  validates :entity, presence: true

  def to_soap
    if self.entity
      self.to_xml_body
      self.soap = self.add_envelope(self.xml)
    else
      "No entity details - set your entity hash"
    end
  end

  def dom_information
    if self.verification_id.present?
      self.to_dom("dyn:GetVerificationResult", self.get_result)
    else
      self.to_dom("dyn:registerVerification", self.register_verification)
    end
  end

  def to_xml_body
    doc = dom_information.to_xml
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
      else
        builder.send(node, data, attrs)
      end
    end
    doc.doc
  end

  def register_verification
    name = {
       :"honorific" => self.entity[:title].to_s,
       :"givenName" => self.entity[:first_given_name].to_s,
       :"middleNames" => self.entity[:other_given_name].to_s,
       :"surname" => self.entity[:family_name].to_s
    }

    current_address = {
        :'level' => (self.entity[:current_address][:level]),
        :'suburb' => (self.entity[:current_address][:suburb]),
        :'state' => (self.entity[:current_address][:state]),
        :'postcode' => (self.entity[:current_address][:postcode]),
        :'country' => (self.entity[:current_address][:country])
    }

    previous_address = {
        :'level' => (self.entity[:previous_address][:level]),
        :'suburb' => (self.entity[:previous_address][:suburb]),
        :'state' => (self.entity[:previous_address][:state]),
        :'postcode' => (self.entity[:previous_address][:postcode]),
        :'country' => (self.entity[:previous_address][:country])
    }

    dob = self.entity[:date_of_birth].to_date

    date_of_birth = {
      :"day" => dob.day,
      :"month" => dob.month,
      :"year" => dob.year
    }

    extra_data = [
        { :'name' => 'greenid_passportdvs_number', :'value' => self.entity[:passport_number] },
        { :'name' => "driversLicenceState", :'value' => (self.entity[:drivers_licence_state_code]) },
        { :'name' => "driversLicenceNumber", :'value' => (self.entity[:drivers_licence_number]) }
    ]

    { :"accountId" => self.access[:access_code],
      :"password" => self.access[:password],
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

  def get_result
    { :"accountId" => self.access[:access_code],
      :"password" => self.access[:password],
      :"verificationId" => self.verification_id
    }
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
      HTTParty.post(self.access[:url], body: self.soap, headers: {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'})
    else
      "No soap envelope to post! - run to_soap"
    end
  end
end
