ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.string :key, :null => false
    t.string :ssn
    t.string :key
    t.string :name
    t.datetime :anniversary
    t.integer :age

    t.timestamps
  end

end