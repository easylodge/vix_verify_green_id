class CreateVixVerifyGreenIdRequest < ActiveRecord::Migration
  def self.change
    create_table :vix_verify_green_id_requests do |t|
      t.integer :ref_id
      t.text :xml
      t.text :soap
      t.text :access
      t.text :entity
      t.text :enquiry

      t.timestamps
    end
  end
end
