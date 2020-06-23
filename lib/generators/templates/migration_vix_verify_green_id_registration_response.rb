class CreateVixVerifyGreenIdRegistrationResponse < ActiveRecord::Migration
  def change
    create_table :vix_verify_green_id_registration_responses do |t|
      t.text :headers
      t.integer :code
      t.text :xml
      t.boolean :success
      t.integer :request_id
      t.string :verification_id
      t.string :verification_token
      t.timestamps
    end

    remove_column :vix_verify_green_id_requests, :verification_id, :string
    remove_column :vix_verify_green_id_requests, :verification_token, :string
  end
end
