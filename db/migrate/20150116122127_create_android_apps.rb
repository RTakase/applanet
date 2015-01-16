class CreateAndroidApps < ActiveRecord::Migration
  def change
    create_table :android_apps do |t|

      t.string :packageid
      t.string  :title
      t.string :iconurl
      t.string :category
      t.string :developer
      t.string :simapps, array:true
      t.text :description
      t.float :rateaverage
      t.integer :ratecount
      
      t.timestamps
    end
  end
end
