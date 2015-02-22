require "sequel"
require "progress_bar"
require "thread/pool"

module LocationHelper

	def process()
		process_birth()
		process_work()
		process_degree()
	end

	def process_birth()
		connection = ConnectionHelper::ConnectionDB.new
		
		locations = {}
		result = connection.get_locations_birth()
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
		# locations = Hash[locations.sort]

		bar = ProgressBar.new(locations.size)
		puts "Extract Locations by LatLon"
		loc_latlon = {}
		locations.each{|index, value|

			latlon = connection.get_position(
				locations[index][:location][:city], 
				locations[index][:location][:state], 
				locations[index][:location][:country]
			)
			latlon_index = (latlon.nil?)? " " : latlon[:latitude].to_s+latlon[:longitude].to_s
			
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

		Location.import([:id, :city, :city_ascii, :state, :country, :country_ascii, :country_abbr, :latitude, :longitude], temp_loc)
		Person.import([:id, :id16, :location_id], temp_people)

		# result.size = 211.898
		# locations.size = 11.870
		# loc_latlon.size = 5.917 - 1
		# (11870-5917-1)/11869 ~ 50%
		# loc_latlon[:" "][:ids].size = 15863
		# (211898-15863)/211898 ~ 92,5%
		byebug
	end

	def process_work()
		connection = ConnectionHelper::ConnectionDB.new
		
		locations = {}
		result = connection.get_locations_work()
		bar = ProgressBar.new(result.size)
		puts "Extract Locations by place"
		result.each{|l|
			bar.increment!
			name = UtilHelper::Util.process_downcase(l[:place])
			place = UtilHelper::Util.process_ascii(name).to_sym

			locations[place] ||= {} 
			locations[place][:instituition_ascii] = place.to_s
			locations[place][:instituition] = name
			locations[place][:ids] ||= []
			locations[place][:ids] << l[:id16]
		}

		bar = ProgressBar.new(locations.size)
		puts "Extract Locations by LatLon"
		loc_latlon = {}
		locations.each{|index, value|
			bar.increment!
			latlon = connection.get_position_by_instituition(locations[index][:instituition_ascii])
			latlon_index = (latlon.nil?)? " " : latlon[:latitude].to_s+latlon[:longitude].to_s

			loc_latlon[latlon_index.to_sym] ||= {}
			loc_latlon[latlon_index.to_sym][:latlon] = latlon
			loc_latlon[latlon_index.to_sym][:places] ||= {}
			loc_latlon[latlon_index.to_sym][:places][locations[index][:instituition_ascii].to_sym] ||= [] 
			loc_latlon[latlon_index.to_sym][:places][locations[index][:instituition_ascii].to_sym] |= value[:ids]
		}


		countLoc = 0
		storesLoc = []
		storesInst = []
		bar = ProgressBar.new(loc_latlon.size)
		puts "Create store"

		loc_latlon.each{|index, value|
			countLoc += 1
			storesLoc << {location_id: countLoc, location: value[:latlon]}
			value[:ids].each{|id16|
				if value[:latlon].nil?
					storesPeople << {id16: id16, location_id: nil}
				else
					storesPeople << {id16: id16, location_id: countLoc}
				end
				bar.increment!
			}
		}

		# 210551 ~ 600
		# (210551-62455)/210551 ~ 70%
		byebug
	end

	def process_degree()
		connection = ConnectionHelper::ConnectionDB.new
		
		locations = {}
		result = connection.get_locations_degree()
		bar = ProgressBar.new(result.size)
		puts "Extract Locations by place"
		result.each{|l|
			bar.increment!
			name = UtilHelper::Util.process_downcase(l[:place])
			place = UtilHelper::Util.process_ascii(name).to_sym

			locations[place] ||= {} 
			locations[place][:instituition_ascii] = place.to_s
			locations[place][:instituition] = name
			locations[place][:idsdeg] ||= []
			locations[place][:idsdeg] << {id16: l[:id16], kind: l[:kind_couse]}
		}

		bar = ProgressBar.new(locations.size)
		puts "Extract Locations by LatLon"
		loc_latlon = {}
		locations.each{|index, value|
			bar.increment!
			latlon = connection.get_position_by_instituition(locations[index][:instituition_ascii])
			latlon_index = (latlon.nil?)? " " : latlon[:latitude].to_s+latlon[:longitude].to_s

			loc_latlon[latlon_index.to_sym] ||= {}
			loc_latlon[latlon_index.to_sym][:latlon] = latlon
			loc_latlon[latlon_index.to_sym][:places] ||= {}
			loc_latlon[latlon_index.to_sym][:places][locations[index][:instituition_ascii].to_sym] ||= [] 
			loc_latlon[latlon_index.to_sym][:places][locations[index][:instituition_ascii].to_sym] |= value[:idsdeg]
		}

		# 920318 ~ 71764 -1 locais com latlon
		# loc_latlon[:" "][:"places"].size = 69986
		# names = []; loc_latlon[:" "][:"places"].each{|k,v| names<< k}
		# File.write("namesprodeg.txt",names.sort.join("\n"))
		# deg = 0; loc_latlon[:" "][:"places"].each{|k,v| deg += v.size} = 161545
		# (920318-161545)/920318 = 758773/920318 ~ 82,4
		# byebug


	end

end




