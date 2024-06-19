class VixVerifyGreenId::Response < ActiveRecord::Base
  self.table_name = "vix_verify_green_id_responses"
  belongs_to :request, dependent: :destroy, inverse_of: :response

  serialize :headers
  serialize :struct

  SOURCE_ABBR_MAP = {
    :actrego => "ACT Driver's Licence",
    :actregodvs => "DVS ACT Driver's Licence",
    :aec => "Australian Electoral Roll",
    :birthcertificatedvs => "DVS Birth Certificate (BDM)",
    :centrelinkdvs => "DVS Centrelink Concession Card	",
    :changeofnamecertificatedvs => "DVS Change of Name Certificate (BDM)",
    :citizenshipcertificatedvs => "DVS Citizenship Certificate",
    :dnb => "illion credit header",
    :docupload => "Document Upload",
    :immicarddvs => "DVS Immicard",
    :marriagecertificatedvs => "DVS Marriage Certificate (BDM)",
    :medibank => "Medibank Private",
    :medicaredvs => "DVS Medicare",
    :nswrego => "NSW driver's licence",
    :nswregodvs => "DVS NSW driver's licence",
    :ntregodvs => "DVS NT driver's licence",
    :passportdvs => "DVS Australian Passport",
    :qldrego => "Queensland driver's licence",
    :qldregodvs => "DVS Queensland driver's licence",
    :sarego => "SA driver's licence",
    :saregodvs => "DVS SA driver's licence",
    :tasregodvs => "DVS Tasmanian driver's licence",
    :vicec => "Victorian electoral roll",
    :vicrego => "Victorian driver's licence",
    :vicrego_old => "Victorian driver's licence",
    :vicregodvs => "DVS Victorian driver's licence",
    :visa => "Work Visa check",
    :visadvs => "DVS Visa (foreign passport)",
    :warego => "WA driver's licence",
    :waregodvs => "DVS WA driver's licence"
  }

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

  def source_list 
    result = self.to_hash
    sources = result["Envelope"]["Body"]["getVerificationResultResponse"]["return"]["sourceList"]["source"]
    sources = [sources] if sources.is_a?(Hash)
    sources.each_with_object([]) do |source, arr|
      next if source["state"] == "EMPTY"
      arr << {
        name: SOURCE_ABBR_MAP[source["name"].to_sym],
        passed: source["passed"],
        state: source["state"],
      }
    end
  end

  def result_indicator
    raw_result["verificationResult"]["overallVerificationStatus"]
  rescue
    nil
  end

  def result_verification_id
    self.to_hash["Envelope"]["Body"]["getVerificationResultResponse"]["return"]["verificationResult"]["verificationId"]
  rescue
    nil
  end

end
