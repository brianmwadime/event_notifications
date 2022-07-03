class AddProjectFormatStore < ActiveRecord::Migration[5.2]
  def change
    unless column_exists? :projects, :format_store
      add_column :projects, :format_store, :text 
    end
  end
end