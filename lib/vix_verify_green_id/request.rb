class VixVerifyGreenId::Request < ActiveRecord::Base
  self.table_name = "vix_verify_green_id_requests"
  has_one :response, dependent: :destroy, inverse_of: :request
  serialize :access
  serialize :entity
  serialize :enquiry

  validates :ref_id, presence: true
  validates :access, presence: true
  validates :entity, presence: true
  validates :enquiry, presence: true

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

    dob = Date.parse(self.entity[:date_of_birth])

    date_of_birth = {
      :"day" => dob.day,
      :"month" => dob.month,
      :"year" => dob.year
    }

    { :"accountId" => self.access[:account_id],
      :"password" => self.access[:password],
      :"verificationId" => self.entity[:verification_id],
      :"ruleId" => self.access[:rule_id],
      :"name" => name,
      :"email" => self.entity[:email_address].to_s,
      :"currentResidentialAddress" => current_address,
      :"previousResidentialAddress" => previous_address,
      :"dob" => date_of_birth,
      :"homePhone" => self.entity[:home_phone_number].to_s,
      :"workPhone" => self.entity[:work_phone_number].to_s,
      :"mobilePhone" => self.entity[:mobile_phone_number].to_s
    }
  end
end
