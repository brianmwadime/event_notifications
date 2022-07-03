class AddEventColToMembers < ActiveRecord::Migration[4.2]
  def change
	  add_column :members, :events, :text
	  Member.update_events!
  end
end
