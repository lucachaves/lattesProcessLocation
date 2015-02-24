require 'csv'

module ProcessHelper

	class ProcessLocations

		def process_locations()
			process_birth()
			process_work()
			process_degree()
			store()
		end

		def process_birth()
			puts "\n=============== BIRTH ==================="

			connection = ConnectionHelper::ConnectionDB.new
			
			locations = {}
			result = connection.get_locations_birth()
			result_size = result.size
			bar = ProgressBar.new(result_size)
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
			result = nil

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
			locations = nil

			@countLoc = 0
			@countPeople = 0
			@storesLoc = {}
			@storesPeople = {}
			bar = ProgressBar.new(result_size)
			puts "Create store"
			loc_latlon.each{|index, value|
				if @storesLoc[index].nil? and index != :" "
					@countLoc += 1
					@storesLoc[index] = {location_id: @countLoc, location: value[:latlon]}
				end
				value[:ids].each{|id16|
					@countPeople += 1
					if value[:latlon].nil?
						@storesPeople[id16] = {person_id: @countPeople, id16: id16, location_id: nil}
					else
						@storesPeople[id16] = {person_id: @countPeople, id16: id16, location_id: @countLoc}
					end
					bar.increment!
				}
			}

			# byebug
			# result.size = 211.898
			# locations.size = 11.870
			# loc_latlon.size = 5.917 - 1
			# (11870-5917-1)/11869 ~ 50%
			# loc_latlon[:" "][:ids].size = 15863
			# (211898-15863)/211898 ~ 92,5%
		end

		def process_work()
			puts "\n=============== WORK ==================="

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
			result = nil

			bar = ProgressBar.new(locations.size)
			puts "Extract Locations by LatLon"
			loc_latlon = {}
			locations.each{|index, value|
				bar.increment!
				instituition_ascii = locations[index][:instituition_ascii]
				result_inst = connection.get_position_by_instituition(instituition_ascii)
				latlon_index = if(result_inst[:latlon] == nil and result_inst[:instituition] == nil)
					" "
				else
					result_inst[:latlon][:latitude].to_s+result_inst[:latlon][:longitude].to_s
				end

				loc_latlon[latlon_index.to_sym] ||= {}
				loc_latlon[latlon_index.to_sym][:latlon] = result_inst[:latlon]
				loc_latlon[latlon_index.to_sym][:instituitions] ||= {}
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym] ||= {} 
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym][:instituition] = result_inst[:instituition]
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym][:ids] ||= [] 
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym][:ids] |= value[:ids]
			}
			locations = nil

			@countInst = 0
			@storesInst = {}
			bar = ProgressBar.new(loc_latlon.size)
			puts "Create store"
			loc_latlon.each{|latlon_index, loc|
				bar.increment!
				if @storesLoc[latlon_index].nil? and latlon_index != :" "
					@countLoc += 1
					@storesLoc[latlon_index] = {location_id: @countLoc, location: loc[:latlon]}
				end
				loc[:instituitions].each{|instituition_index, instituition|
					instituition[:ids].each{|id16|
						if latlon_index == :" "
							@storesPeople[id16][:instituition_id] = nil
						else
							if @storesInst[instituition_index].nil?
								@countInst += 1
								@storesInst[instituition_index] = {instituition_id: @countInst, instituition: instituition[:instituition], location_id: @storesLoc[latlon_index][:location_id]}
							end
							@storesPeople[id16][:instituition_id] = @storesInst[instituition_index][:instituition_id]
						end
					}
				}
			}

			# byebug
			# result.size = 210.551
			# locations.size = 21.216
			# loc_latlon.size = 646 - 1
			# (21217-646-1)/21217 ~ 97%
			# loc_latlon[:" "][:instituitions].size = 19.462
			# (210551-19462)/210551 ~ 90,7%
		end

		def process_degree()
			puts "\n=============== DEGREE ==================="

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
				# TODO validate year
				locations[place][:idsdeg] << {id16: l[:id16], kind: l[:kind], start_year: l[:start_year], end_year: l[:end_year]}
			}
			result = nil

			bar = ProgressBar.new(locations.size)
			puts "Extract Locations by LatLon"
			loc_latlon = {}
			locations.each{|index, value|
				bar.increment!
				instituition_ascii = locations[index][:instituition_ascii]
				result_inst = connection.get_position_by_instituition(instituition_ascii)
				latlon_index = if(result_inst[:latlon] == nil and result_inst[:instituition] == nil)
					" "
				else
					result_inst[:latlon][:latitude].to_s+result_inst[:latlon][:longitude].to_s
				end

				loc_latlon[latlon_index.to_sym] ||= {}
				loc_latlon[latlon_index.to_sym][:latlon] = result_inst[:latlon]
				loc_latlon[latlon_index.to_sym][:instituitions] ||= {}
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym] ||= {} 
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym][:instituition] = result_inst[:instituition]
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym][:idsdeg] ||= [] 
				loc_latlon[latlon_index.to_sym][:instituitions][instituition_ascii.to_sym][:idsdeg] |= value[:idsdeg]
			}
			locations = nil

			@countKind = 0
			@storesDegree = []
			bar = ProgressBar.new(loc_latlon.size)
			puts "Create store"
			loc_latlon.each{|latlon_index, loc|
				bar.increment!
				if @storesLoc[latlon_index].nil? and latlon_index != :" "
					@countLoc += 1
					@storesLoc[latlon_index] = {location_id: @countLoc, location: loc[:latlon]} if @storesLoc[latlon_index].nil?
				end
				if latlon_index != :" "
					loc[:instituitions].each{|instituition_index, instituition|
						instituition[:idsdeg].each{|idsdeg|
							if @storesInst[instituition_index].nil?
								@countInst += 1
								@storesInst[instituition_index] = {instituition_id: @countInst, instituition: instituition[:instituition], location_id: @storesLoc[latlon_index][:location_id]}
							end
							@countKind += 1
							@storesDegree << {degree_id: @countKind, name: idsdeg[:kind], start_year: idsdeg[:start_year], end_year: idsdeg[:end_year], instituition_id: @storesInst[instituition_index][:instituition_id], person_id: @storesPeople[idsdeg[:id16]][:person_id]}
						}
					}
				end
			}

			# byebug
			# result.size = 920.318
			# locations.size = 71.764
			# loc_latlon.size = 639 -1
			# (71764-639-1)/71764 ~ 99%
			# loc_latlon[:" "][:instituitions].size = 69.985
			# (920318-69985)/920318 ~ 92,3%
		end

		def store()
			puts "\n=============== STORE ==================="

			data_time = ['2015-02-23 20:35:19.727272','2015-02-23 20:35:20.639139']
			data_loc = []
			data_people = []
			data_deg = []
			data_inst = []

			header_time = [:created_at, :updated_at]
			header_loc = [:id, :city, :city_ascii, :state, :country, :country_ascii, :country_abbr, :latitude, :longitude]
			header_inst = [:id, :name, :name_ascii, :abbr, :location_id]
			header_people = [:id, :id16, :location_id, :instituition_id]
			header_deg = [:id, :name, :start_year, :end_year, :instituition_id, :person_id]

			# LOCATIONS - 5989
			bar = ProgressBar.new(@storesLoc.size)
			puts "Create store locatioins"
			@storesLoc.each{|index, store|
				bar.increment!
				unless store[:location].nil?
					data_loc << [
						store[:location_id], 
						store[:location][:city], 
						store[:location][:city_ascii], 
						store[:location][:state], 
						store[:location][:country],
						store[:location][:country_ascii],
						store[:location][:country_code1],
						store[:location][:latitude],
						store[:location][:longitude],'2015-02-23 20:35:19.727272','2015-02-23 20:35:20.639139']
						# store[:location][:longitude]
					# ]
				end
			}

			# INSTITUITIONS - 2103
			bar = ProgressBar.new(@storesInst.size)
			puts "Create store instituitions"
			@storesInst.each{|index, store|
				bar.increment!
				data_inst << [
					store[:instituition_id],
					store[:instituition][:name],
					store[:instituition][:name_ascii],
					store[:instituition][:abbr],
					store[:location_id],'2015-02-23 20:35:19.727272','2015-02-23 20:35:20.639139']
					# store[:location_id]
				# ]
			}

			# PEOPLE - 211898
			bar = ProgressBar.new(@storesPeople.size)
			puts "Create store people"
			@storesPeople.each{|index, store|
				bar.increment!
				data_people << [
					store[:person_id],
					store[:id16],
					store[:location_id], 
					store[:instituition_id],'2015-02-23 20:35:19.727272','2015-02-23 20:35:20.639139']
					# store[:instituition_id]
				# ]
			}

			# DEGREES - 724824
			bar = ProgressBar.new(@storesDegree.size)
			puts "Create store degrees"
			@storesDegree.each{|store|
				bar.increment!
				data_deg << [
					store[:degree_id],
					store[:name],
					store[:start_year],
					store[:end_year],
					store[:instituition_id],
					store[:person_id],'2015-02-23 20:35:19.727272','2015-02-23 20:35:20.639139']
					# store[:person_id]
				# ]
			}

			store_csv(header_loc|header_time, data_loc, "locations")
			store_csv(header_inst|header_time, data_inst, "instituitions")
			store_csv(header_people|header_time, data_people, "people")
			store_csv(header_deg|header_time, data_deg, "degrees")
			
			byebug
			
			# Location.import(header_loc, data_loc)
			# Instituition.import(header_inst, data_inst)
			# Person.import(header_people, data_people)
			# Degree.import(header_deg, data_deg)
		end

		def store_csv(header, datas, filename)
			bar = ProgressBar.new(datas.size)
			csv_string = CSV.generate(:col_sep => ";") do |csv|
				csv << header
				datas.each{|data|
					csv << data
					bar.increment!
				}
			end
			File.write("app/helpers/store/#{filename}.csv", csv_string)
		end
	end

end
