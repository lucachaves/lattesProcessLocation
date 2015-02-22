class Instituition < ActiveRecord::Base
  belongs_to :location
  has_many :degrees
  has_many :people
end
