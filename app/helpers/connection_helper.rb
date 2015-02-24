module ConnectionHelper

	class ConnectionDB
		def initialize()
			ip = "192.168.56.101"
			@geonames = Sequel.connect("postgres://postgres:postgres@#{ip}/geonames")
			@location_dump = Sequel.connect("postgres://postgres:postgres@#{ip}/latteslocationdumpdoutorado")
			@cities_br = Sequel.connect("postgres://postgres:postgres@#{ip}/munic")
		end

		def get_locations()
			@location_dump[:locations].all
		end

		def get_locations_birth()
			@location_dump[:locations].where(kind: 'birth').all
		end

		def get_locations_work()
			@location_dump[:locations].where(kind: 'work').all
		end

		def get_locations_degree()
			@location_dump[:locations].where(Sequel.~(:kind => 'birth') & Sequel.~(:kind => 'work')).all
		end

		def get_distinct_locations_birth()
			@location_dump[:locations].where(kind: 'birth').order(:country).distinct(:country).all
		end	

		def get_city(city)
			@location_dump[:cities].where(city_ascii: city).all
		end

		def get_city_by_country(city, country)
			result = @location_dump[:countries].where(name_ascii_pt: country).or(name_en: country).all[0]
			@location_dump[:cities].where(city_ascii: city, country_ascii: result[:name_en]).all
		end

		def get_city_by_state(city, state)
			@location_dump[:cities].where(city_ascii: city, country_ascii: "brazil", state_code: state).all
		end

		def get_city_by_instituition(name)
			@location_dump[:instituitions].where(name_ascii: name).all
		end

		def get_position(city, state, country)
			return nil if city.nil? or city == ''
			result_city = get_city(city)
			if(result_city.size == 1)
				return result_city[0]
			end

			return nil if country.nil? or country == ''
			result_country = get_city_by_country(city, country)
			if(result_city.size > 1 and result_country.size == 1)
				return result_country[0]
			end
			
			return nil if state.nil? or state == ''
			result_state_br = get_city_by_state(city, state)
			if(result_city.size > 1 and result_country.size > 1 and (country == "brasil" or country == "brazil") and result_state_br.size == 1)
				return result_state_br[0]
			end
				
			nil
		end

		def get_position_by_latlon(latitude, longitude)
			@location_dump[:cities].where(latitude: latitude, longitude: longitude).all
		end

		def get_position_by_instituition(name)
			default = {latlon: nil, instituition: nil}

			return default if name.nil? or name == ''
			
			result_name = get_city_by_instituition(name)
			if(result_name.size == 1)
				result = get_position_by_latlon(result_name[0][:latitude], result_name[0][:longitude])
				return {latlon: result[0], instituition: result_name[0]}
			end
			
			default
		end
	end
	
end
