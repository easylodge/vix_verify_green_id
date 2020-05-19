class CreateVixVerifyGreenIdRequest < ActiveRecord::Migration
  def change
    create_table :vix_verify_green_id_requests do |t|
      t.integer :ref_id
      t.string :verification_id
      t.string :verification_token
      t.text :xml
      t.text :soap
      t.text :access
      t.text :entity

      t.timestamps
    end
  end
end
