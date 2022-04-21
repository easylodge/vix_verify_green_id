class VixVerifyGreenId::Response < ActiveRecord::Base
  self.table_name = "vix_verify_green_id_responses"
  belongs_to :request, dependent: :destroy, inverse_of: :response

  serialize :headers
  serialize :struct

  def initialize(options={})
    if options[:headers]
      options[:headers] = (options[:headers].to_h rescue {}) unless options[:headers].is_a?(Hash)
    end
    super(options)
  end


  def to_hash
    if self.xml
      Hash.from_xml(self.xml)
    else
      "No hash was created because there was no xml"
    end
  end

  def error
    if self.xml && !self.success?
      result = self.to_hash
      result["Envelope"]["Body"]["Fault"]["detail"]["faultDetails"]["details"]
    else
      "No error"
    end
  end

  def raw_result
    result = self.to_hash
    result["Envelope"]["Body"]["setFieldsResponse"]["return"]
  rescue
    {}
  end

  def result_indicator
    raw_result["verificationResult"]["overallVerificationStatus"]
  rescue
    nil
  end

end
