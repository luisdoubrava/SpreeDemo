# This migration comes from spree_homepager (originally 20120317183333)
class AddPlaceToBanners < ActiveRecord::Migration
  def change
    add_column :spree_banners, :place, :string
  end
end
