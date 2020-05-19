ActiveRecord::Schema.define do
  self.verbose = false

  create_table :vix_verify_green_id_requests do |t|
    t.integer :ref_id
    t.string :verification_id
    t.string :verification_token
    t.text :xml
    t.text :soap
    t.text :access
    t.text :entity
    t.text :enquiry
    t.timestamps
  end

  create_table :vix_verify_green_id_responses  do |t|
    t.text :headers
    t.integer :code
    t.text :xml
    t.boolean :success
    t.integer :request_id
    t.timestamps
  end
end
