class CreateBeavers < ActiveRecord::Migration
  def change
    create_table :beavers do |t|
      t.string :name

      t.timestamps
    end
  end
end
