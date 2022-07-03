class AddEventColToMembers < ActiveRecord::Migration[5.2]
  def change
	  add_column :members, :events, :text
	  Member.update_events!
  end
end
