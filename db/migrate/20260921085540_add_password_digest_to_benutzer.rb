class AddPasswordDigestToBenutzer < ActiveRecord::Migration[8.1]
  def change
    add_column :benutzer, :password_digest, :string
  end
end
