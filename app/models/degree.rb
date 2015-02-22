class Degree < ActiveRecord::Base
  belongs_to :instituition
  belongs_to :person
end
