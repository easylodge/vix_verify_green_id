require 'active_record'
require 'vix_verify_green_id/version'
require 'vix_verify_green_id/request'
require 'vix_verify_green_id/registration_response'
require 'vix_verify_green_id/response'
require 'nokogiri'
require 'httparty'
require 'vix_verify_green_id/railtie' if defined?(Rails)

module VixVerifyGreenId
end
