require 'csv'

module ConnectionHelper

	class ConnectionDB
		def initialize()
			@geonames = Sequel.connect('postgres://postgres:postgres@192.168.56.101/geonames')
			@location_dump = Sequel.connect('postgres://postgres:postgres@192.168.56.101/latteslocationdumpdoutorado')
			@cities_br = Sequel.connect('postgres://postgres:postgres@192.168.56.101/munic')
		end
	end

	class LocationLattesDump < ConnectionDB

		def initialize()
			super
		end

		def get_locations()
			@location_dump[:locations].all
		end

		def get_locations_birth()
			@location_dump[:locations].where(kind_course: 'birth').all
		end

		def get_distinct_locations_birth()
			@location_dump[:locations].where(kind_course: 'birth').order(:country).distinct(:country).all
			# @location_dump[:locations].where(kind_course: 'birth').order(:country, :state, :city).distinct(:country, :state, :city).all
		end

		def get_id16s()
			@location_dump[:locations].order(:id16).distinct(:id16).map{|row| row[:id16]}
			# @location_dump[:locations].limit(10).order(:id16).distinct(:id16).map{|row| row[:id16]}
		end

		def get_ids()
			@location_dump[:locations].map{|row| row[:id]}
		end

		def get_birth(id16)
			@location_dump[:locations].where(id16: id16, kind_course: 'birth').all
		end

		def get_work(id16)
			@location_dump[:locations].where(id16: id16, kind_course: 'work').all
		end
	
		def get_degrees(id16)
			@location_dump[:locations].where("id16 = '#{id16}' and kind_course != 'birth' and kind_course != 'work'").all
		end

	# end

	# class LocationProcess < ConnectionDB
		
	# 	def initialize()
	# 		super
	# 	end

		

		def get_city_geoname(city)
			@geonames[:geoname].where(Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(city))).all
		end

		def get_city_geoname_by_country(city, country)
			countrycode = get_country_by_name(country)
			@geonames[:geoname].where(
				Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(city)),
				Sequel.ilike(:country, countrycode)
			).all
		end

		def get_city_geoname_by_country_and_state(city, state, countrycode)
			statename = UtilHelper::Util.state_br(state)
			state = get_state2(countrycode, statename)
			state = state[0]
			@geonames[:geoname].where(
				Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(city)),
				Sequel.ilike(:admin1, state[:admin1_code]),
				Sequel.ilike(:country, countrycode)
			).all
		end

		def get_city_br(city)
			@cities_br[:munic].where(nome_ascii: city).all
		end

		def get_state(contrycode, name)
			@geonames[:admin1codes].where(countrycode: contrycode, admin1_code: name).all
		end

		def get_state2(contrycode, statename)
			@geonames[:admin1codes].where(Sequel.ilike(:countrycode, countrycode), Sequel.ilike(:alt_name_english, statename)).all
		end

		def get_country_by_code(country)
			@geonames[:countryinfo].where(iso_alpha2: country).all
		end

		def get_country_by_name(country)
			contrycode = nil
			country = @location_dump[:countries].where(name_pt: country).all[0]
			country = @location_dump[:countries].where(name_ascii_pt: country).all[0] if country.nil?
			country = @location_dump[:countries].where(name_en: country).all[0] if country.nil?
			return nil if country.nil?
			geocountry = @geonames[:countryinfo].where(Sequel.ilike(:name, country[:name_en])).all[0]
			countrycode = geocountry[:iso_alpha2] if !geocountry.nil?
			contrycode
		end

		def create_location(place)
			place = UtilHelper::Util.process_fields(place)
			place[:latitude] = nil
			place[:longitude] = nil
			# get_latitude(place)
			get_latitude2(place)
			# result = get_latitude(place)
			# place = result unless result.nil?
			# place
		end

		def create_place_munic(geoname)
			place = {}

			place[:city] = geoname[:nome] 
			place[:city_ascii] = geoname[:nome_ascii]
			place[:state] = UtilHelper::Util.state_br(geoname[:uf])
			place[:state_ascii] = geoname[:uf] 
			place[:country] = 'brazil'
			place[:country_ascii] = 'brazil'
			place[:country_abbr] = 'BR'
			place[:latitude] = geoname[:latitude].to_f
			place[:longitude] = geoname[:longitude].to_f
			
			place = UtilHelper::Util.process_fields(place)
		end

		def create_place_geoname(geoname)
			place = {}
			state = get_state(geoname[:country], geoname[:admin1])
			state = state[0]
			# byebug
			country = get_country_by_code(geoname[:country])
			country = country[0]
			return nil if country.nil? or state.nil?

			place[:city] = geoname[:name] 
			place[:city_ascii] = geoname[:asciiname]
			place[:state] = state[:name] 
			place[:state_ascii] = state[:alt_name_english] 
			place[:country] = country[:name]
			place[:country_ascii] = country[:name]
			place[:country_abbr] = country[:iso_alpha2]
			place[:latitude] = geoname[:latitude]
			place[:longitude] = geoname[:longitude]
			
			place = UtilHelper::Util.process_fields(place)
		end

		def insert_location(place)
			l = Location.find_or_create_by(
				city: place[:city], 
				city_ascii: place[:city_ascii], 
				uf: place[:state], 
				country: place[:country],
				country_ascii: place[:country_ascii],
				country_abbr: place[:country_abbr],
				latitude: place[:latitude],
				longitude: place[:longitude]
			)
		end

		def get_latitude(location)
			if (location[:city].nil? or location[:city] == '') 
				return nil
			end
			geoname = get_city_geoname(location[:city_ascii])
		
			if geoname.size == 1
				create_place_geoname(geoname.first)
			elsif geoname.size > 1
				if (location[:country].nil? or location[:country] == '')
					return nil
				end
				
				result = get_city_geoname_by_country(location[:city_ascii], location[:country])
				if result.size == 1
					create_place_geoname(result[0])
				elsif result.size > 1 and location[:country] == "brasil"
					if (location[:state].nil? or location[:state] == '')
						return nil
					end
					r = get_city_geoname_by_country_and_state(location[:city_ascii], location[:state], countrycode)
					if r.size == 1
						create_place_geoname(r[0])
					else
						nil
					end
				elseif result.size == 0
					nil
				end

			elsif geoname.size == 0
				geoname = get_city_br(location[:city_ascii])
				return nil if geoname == []
				create_place_munic(geoname.first)
			end
		end

		def get_city(city)
			@location_dump[:cities].where(Sequel.ilike(:city_ascii, city)).all
		end

		def get_city_by_country(city, country)
			country2 = @location_dump[:countries].where(Sequel.ilike(:name_ascii_pt, country)).or(Sequel.ilike(:name_en, country)).all[0]
			byebug if country2.nil?
			@location_dump[:cities].where(
				Sequel.ilike(:city_ascii, city), 
				Sequel.ilike(:country_ascii, country2[:name_en])
			).all
		end

		def get_city_by_state(city, state)
			@location_dump[:cities].where(city_ascii: city, country_ascii: "brasil", state_code: state).all
		end

		def get_position(city, state, country)

			return nil if city.nil? or city == ''
			city = UtilHelper::Util.process_ascii(city)
			result_city = get_city(city)
			
			if(result_city.size == 1)
				return result_city[0]
			end

			return nil if country.nil? or country == ''
			country = UtilHelper::Util.process_ascii(country)
			result_country = get_city_by_country(city, country)
			if(result_city.size > 1 and result_country.size == 1)
				return result_country[0]
			end
			
			return nil if state.nil? or state == ''
			state = UtilHelper::Util.process_ascii(state)
			result_state_br = get_city_by_state(city, state)
			if(result_city.size > 1 and result_country.size > 1 and country == "brasil" and result_state_br.size == 1)
				return result_state_br[0]
			end
				
			nil
		end
	end

	
end
