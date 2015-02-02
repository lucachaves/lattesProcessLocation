class Degree < ActiveRecord::Base
  belongs_to :university
  belongs_to :person
end
