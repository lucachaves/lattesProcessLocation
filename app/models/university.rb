class University < ActiveRecord::Base
  belongs_to :location
  has_many :degrees
end
