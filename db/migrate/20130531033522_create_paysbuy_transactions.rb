class CreatePaysbuyTransactions < ActiveRecord::Migration
  def change
    create_table :spree_paysbuy_transactions do |t|
      t.string :result
      t.string :ap_code
      t.decimal :amount, :precision => 9, :scale => 2
      t.decimal :fee, :precision => 9, :scale => 2
      t.string :method
      t.string :confirm_cs
      t.timestamps
    end
  end
end

