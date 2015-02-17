require "sequel"
require "progress_bar"
require "thread/pool"

module LocationHelper

	def process()
		# TODO criar SQL único
		c = ConnectionHelper::LocationLattesDump.new
		
		locations = []
		c.get_locations_birth().each{|l|
			location = {}
			name = [l[:city], l[:state], l[:country]].join(", ")
			location[:location] = {city: l[:city], state: l[:state], country: l[:country]}
			location[:ids] = [] if location[name].nil?
			location[:ids] << l[:id16]
			locations << location
		}

		bar = ProgressBar.new(211898)
		pool = Thread.pool(50)

		locations.each{|l|
			pool.process do
				place = c.create_location(l[:location])
				next if place.nil?
				point = Location.find_or_create_by(
					city: place[:city], 
					city_ascii: place[:city_ascii], 
					uf: place[:state], 
					country: place[:country],
					country_ascii: place[:country_ascii],
					country_abbr: place[:country_abbr],
					latitude: place[:latitude],
					longitude: place[:longitude]
				)
				l[:ids].each{|id16|
					p = Person.find_or_create_by(id16: id16)
					unless point.nil?
						p.location_id = point.id
						p.save
					end
					bar.increment!
				}
			end
		}
		pool.shutdown

	end

	# TODO criar SQL único
	def processSingle()
		c = ConnectionHelper::LocationLattesDump.new
		
		locations = {}
		result = c.get_locations_birth()
		bar = ProgressBar.new(result.size)
		puts "Extract Locations by place"
		result.each{|l|
			city = UtilHelper::Util.process_ascii(l[:city])
			state = UtilHelper::Util.process_ascii(l[:state])
			country = UtilHelper::Util.process_ascii(l[:country])
			name = [city, state, country].join(", ").to_sym
			locations[name] = {} if locations[name].nil?
			locations[name][:location] = {city: city, state: state, country: country}
			locations[name][:ids] = [] if locations[name][:ids].nil?
			locations[name][:ids] << l[:id16]
			bar.increment!
		}

		bar = ProgressBar.new(locations.size)
		puts "Extract Locations by LatLon"
		loc_latlon = {}
		locations.each{|index, value|

			latlon = c.get_position(
				locations[index][:location][:city], 
				locations[index][:location][:state], 
				locations[index][:location][:country]
			)
			latlon_index = (latlon.nil?)? " " : latlon[:latitude].to_s+latlon[:longitude].to_s
			
			# byebug
			loc_latlon[latlon_index.to_sym] ||= {}
			loc_latlon[latlon_index.to_sym][:latlon] = latlon
			loc_latlon[latlon_index.to_sym][:locations] ||= []
			loc_latlon[latlon_index.to_sym][:locations] << value[:location]
			loc_latlon[latlon_index.to_sym][:ids] ||= []
			loc_latlon[latlon_index.to_sym][:ids] |= value[:ids]
			bar.increment!
		}

		countLoc = 0
		countPeople = 0
		storesLoc = []
		storesPeople = []
		bar = ProgressBar.new(result.size)
		puts "Create store"

		loc_latlon.each{|index, value|
			countLoc += 1
			storesLoc << {location_id: countLoc, location: value[:latlon]}
			value[:ids].each{|id16|
				countPeople += 1
				if value[:latlon].nil?
					storesPeople << {person_id: countPeople, id16: id16, location_id: nil}
				else
					storesPeople << {person_id: countPeople, id16: id16, location_id: countLoc}
				end
				bar.increment!
			}
		}

		temp_loc = []
		temp_people = []
		bar = ProgressBar.new(storesLoc.size)
		puts "Create store locatioins"
		storesLoc.each{|store|
			bar.increment!
			unless store[:location].nil?
				temp_loc << [
					store[:location_id], 
					store[:location][:city], 
					store[:location][:city_ascii], 
					store[:location][:state], 
					store[:location][:country],
					store[:location][:country_ascii],
					store[:location][:country_code1],
					store[:location][:latitude],
					store[:location][:longitude]
				]
			end
		}

		bar = ProgressBar.new(storesPeople.size)
		puts "Create store people"
		storesPeople.each{|store|
			bar.increment!
			temp_people << [
				store[:person_id],
				store[:id16],
				store[:location_id] 
			]
		}

		Location.import([:id, :city, :city_ascii, :uf, :country, :country_ascii, :country_abbr, :latitude, :longitude], temp_loc)
		Person.import([:id, :id16, :location_id], temp_people)

		byebug
	end

end
