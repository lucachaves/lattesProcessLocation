class Person < ActiveRecord::Base
  belongs_to :location
  belongs_to :instituition
  has_many :degrees
end
