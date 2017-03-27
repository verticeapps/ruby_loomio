class Identities::Base < ActiveRecord::Base
  extend HasCustomFields
  self.table_name = :omniauth_identities
  validates :identity_type, presence: true
  validates :access_token, presence: true

  belongs_to :user, required: true
  has_many :communities, class_name: "Communities::Base", foreign_key: :identity_id

  discriminate Identities, on: :identity_type

  def self.set_identity_type(type)
    after_initialize { self.identity_type = type }
  end
end
