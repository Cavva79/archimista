class UpdateFondEvents < ActiveRecord::Migration
  def up
    change_column :fond_events, :note, :text, :limit => 16777215
  end
  def down
    change_column :fond_events, :note, :text, :limit => 16777215
  end
end
