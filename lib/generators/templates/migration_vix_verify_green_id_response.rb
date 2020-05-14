class CreateVixVerifyGreenIdResponse < ActiveRecord::Migration
  def self.change
    create_table :vix_verify_green_id_responses do |t|
      t.text :headers
      t.integer :code
      t.text :xml
      t.boolean :success
      t.integer :request_id
      t.timestamps
    end
  end
end
