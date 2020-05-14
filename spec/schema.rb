ActiveRecord::Schema.define do
  self.verbose = false

  create_table :vixverify_green_id_requests do |t|
    t.integer :ref_id
    t.text :xml
    t.text :soap
    t.text :access
    t.text :entity
    t.text :enquiry
    t.timestamps
  end

  create_table :vixverify_green_id_responses  do |t|
    t.text :headers
    t.integer :code
    t.text :xml
    t.boolean :success
    t.integer :request_id
    t.timestamps
  end
end
