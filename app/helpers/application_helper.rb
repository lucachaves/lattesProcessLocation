require "sequel"

# MUNIC
# geocodigo integer,
# nome character varying(32),
# uf character varying(2),
# id_uf integer,
# regiao character varying(12),
# mesoregiao character varying(34),
# microregia character varying(36),
# latitude numeric(8,4),
# longitude numeric(8,4)

# DBs
# GEOLOCATION
# LOCATIONS - LattesLocation
# LOCATIONS - LattesLocationDump

module ApplicationHelper

	def process_locations()
		loc = LocationLattesDump.new
		id16s = loc.get_id16s()
		
		id16s.each{|id16|
			# id16 = "6489817091609815"
			puts "########## #{id16}"

			birth = loc.get_birth(id16)
			if(birth != [])
				birth_loc = loc.create_location(birth[0])
			end
			
			work = loc.get_work(id16)
			if(work != [])
				work_loc = loc.create_location(work[0])
			end

			degrees = loc.get_degrees(id16)
			degrees.each{|degree|
				degrees_loc = loc.create_location(degree)
			}
		}
	end

	private

		class Util
			class << self
				def process_fields(fields)
					unless fields[:city].nil?
						fields[:city] = process_text(fields[:city]) 
						fields[:city_ascii] = process_ascii(fields[:city])
					end

					fields[:state] = process_text(fields[:state]) unless fields[:state].nil?
					
					unless fields[:country].nil?
						fields[:country] = process_text(fields[:country]) 
						fields[:country_ascii] = process_ascii(fields[:country])
					end

					fields
				end

				def process_text(text)
					text = text.tr(
						"ÀÁÂÃÄÅĀĂĄÇĆĈĊČÐĎĐÈÉÊËĒĔĖĘĚĜĞĠĢĤĦÌÍÎÏĨĪĬĮİĴĵĶĹĻĽĿŁÑŃŅŇŊÒÓÔÕÖØŌŎŐŔŖŘŚŜŞŠŢŤŦÙÚÛÜŨŪŬŮŰŲŴÝŶŸŹŻŽ",
						"àáâãäåāăąçćĉċčðďđèéêëēĕėęěĝğġģĥħìíîïĩīĭįıJjķĺļľŀłñńņňŋòóôõöøōŏőŕŗřśŝşšţťŧùúûüũūŭůűųŵýŷYźżž"
					)
					text = text.downcase
					text.gsub!(/\s+/, " ")
					text.gsub!(/^\s/, "")
					text.gsub!(/\s$/, "")
					text
				end

				def process_ascii(text)
					text = text.tr(
						"ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
						"AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
					)
					text
				end

				def state_br(state)
					states = {
						"ac" => "acre",
						"al" => "alagoas",
						"ap" => "amapa",
						"am" => "amazonas",
						"ba" => "bahia",
						"ce" => "ceara",
						"es" => "espirito Santo",
						"go" => "goias",
						"ma" => "maranhao",
						"mt" => "mato grosso",
						"ms" => "mato grosso do sul",
						"mg" => "minas gerais",
						"pa" => "para",
						"pb" => "paraiba",
						"pr" => "parana",
						"pe" => "pernambuco",
						"pi" => "piaui",
						"rj" => "rio de janeiro",
						"rn" => "rio grande do norte",
						"rs" => "rio grande do sul",
						"ro" => "rondonia",
						"rr" => "roraima",
						"sc" => "santa catarina",
						"sp" => "sao paulo",
						"se" => "sergipe",
						"to" => "tocantins"
					}
					return states[state]
				end
			end
		end

		class LocationLattesDump

			def initialize()
				@con = ConnectionDB.new
				@location_dump = @con.get_location_dump
				@geonames = @con.get_geoname
				@locationGeo = LocationGeoNames.new
				# process_code_country()
			end

			def get_locations()
				@location_dump[:locations].all
			end

			def get_id16s()
				@location_dump[:locations].order(:id16).distinct(:id16).map{|row|
					row[:id16]
				}
			end

			def get_ids()
				@location_dump[:locations].map{|row|
					row[:id]
				}
			end

			def get_birth(id16)
				@location_dump[:locations].where(id16: id16, kind: 'birth').all
			end

			def get_work(id16)
				@location_dump[:locations].where(id16: id16, kind: 'work').all
			end
		
			def get_degrees(id16)
				@location_dump[:locations].where("id16 = '#{id16}' and kind != 'birth' and kind != 'work'").all
			end

			# def process_code_country
			# 	get_ids().each{|id|
			# 		location = @location_dump[:locations].where(id: id).first
			# 		unless location[:codecountry].nil?
			# 			location[:codecountry]
			# 			country = @geonames[:countryinfo].where(iso_alpha3: ).first
			# 			@location_dump[:locations].where(id: id).update(codecountry: country[:iso_alpha2])
			# 		else
			# 			country = @location_dump[:countries].where(name_pt: Util.process_text(location[:country])).first
			# 			unless country.nil?
			# 				name = country[:name_en]
			# 				country = @geonames[:countryinfo].where(Sequel.ilike(:name, name)).first
			# 				@location_dump[:locations].where(id: id).update(codecountry: country[:iso_alpha2])
			# 			end
			# 		end
			# 	}
			# end

			def create_location(place)
				place = Util.process_fields(place)
				place[:latitude] = nil
				place[:longitude] = nil
				result = @locationGeo.get_latitude(place)
				place = result unless result.nil?
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

		end


		class LocationGeoNames

			def initialize()
				@con = ConnectionDB.new
				@location_dump = @con.get_location_dump
				@geonames = @con.get_geoname
			end

			def get_latitude(location)
				if location[:city].nil? # and location[:uf].nil? and location[:country].nil? and location[:country_abbr].nil?
					return nil
				end

				geoname = @geonames[:geoname].where(Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(location[:city_ascii]))).all
				
				if geoname.size == 1
					create_place_geoname(geoname.first)
				elsif geoname.size > 1
					puts " #######{location[:country]} "
					country = @location_dump[:countries].where(name_pt: location[:country]).all[0]
					# byebug
					geocountry = @geonames[:countryinfo].where(Sequel.ilike(:name, country[:name_en])).all[0]
					countrycode = geocountry[:iso_alpha2]

					result = @geonames[:geoname].where(
						Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(location[:city_ascii])),
						Sequel.ilike(:country, countrycode)
					).all
					if result.size == 1
						create_place_geoname(result[0])
					elsif result.size > 1 and location[:country] == "brasil"
						statename = Util.state_br(location[:state])
						state = @geonames[:admin1codes].where(Sequel.ilike(:countrycode, countrycode), Sequel.ilike(:alt_name_english, statename)).all[0]
						r = @geonames[:geoname].where(
							Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(location[:city_ascii])),
							Sequel.ilike(:admin1, state[:admin1_code]),
							Sequel.ilike(:country, countrycode)
						).all
						if r.size == 1
							create_place_geoname(r[0])
						else
							nil
						end
					else
						nil
					end
				elsif geoname == []
					nil
				end


			end

			def create_place_geoname(geoname)
				place = {}
				state = @geonames[:admin1codes].where(countrycode: geoname[:country], admin1_code: geoname[:admin1]).all[0]
				country = @geonames[:countryinfo].where(iso_alpha2: geoname[:country]).first
				
				place[:city] = geoname[:name] 
				place[:city_ascii] = geoname[:asciiname]
				place[:state] = state[:name] 
				place[:state_ascii] = state[:alt_name_english] 
				place[:country] = country[:name]
				place[:country_ascii] = country[:name]
				place[:country_abbr] = country[:iso_alpha2]
				place[:latitude] = geoname[:latitude]
				place[:longitude] = geoname[:longitude]
				
				place = Util.process_fields(place)
			end

		end

		class ConnectionDB
			def initialize()
				@geonames = Sequel.connect('postgres://postgres:postgres@192.168.56.101/geonames')
				@location_dump = Sequel.connect('postgres://postgres:postgres@192.168.56.101/latteslocationdump')
			end

			def get_geoname
				@geonames
			end

			def get_location_dump
				@location_dump
			end
		end

end
