# This migration comes from spree_homepager (originally 20110224163222)
class AddVisibleToBanners < ActiveRecord::Migration
  def self.up
    add_column :spree_banners, :visible, :boolean
    Spree::Banner.update_all :visible => true
  end

  def self.down
    remove_column :spree_banners, :visible
  end
end
