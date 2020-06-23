module VixVerifyGreenId
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../../templates", __FILE__)
      desc "Sets up the Vix Verify green ID Configuration File"

      def self.next_migration_number(dirname)
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      end

      def create_migration_file
        migration_template "migration_vix_verify_green_id_request.rb", "db/migrate/create_vix_verify_green_id_request.rb"
        sleep 1
        migration_template "migration_vix_verify_green_id_response.rb", "db/migrate/create_vix_verify_green_id_response.rb"
        sleep 1
        migration_template "migration_vix_verify_green_id_registration_response.rb", "db/migrate/create_vix_verify_green_id_registration_response.rb"
      end
    end
  end
end