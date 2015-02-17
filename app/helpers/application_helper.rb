require "sequel"
require "progress_bar"

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

	def process_distinct_locations()
		loc = LocationLattesDump.new
		# result = ""
		locations = loc.get_distinct_locations()
		bar = ProgressBar.new(locations.count)
		count = 0
		locations.each{|l|
			r = loc.create_location(l)
			loc.insert_location(r)
			# result << "#{r[:city]}, #{r[:state]}, #{r[:country]}, #{r[:latitude]}, #{r[:longitude]}\n"
			count += 1
			bar.increment!(30) if (count%30 == 0)
		}
		# File.write("temp", result)
	end

	private

		class Util
			@states = {
				"ac" => "acre",
				"al" => "alagoas",
				"ap" => "amapa",
				"am" => "amazonas",
				"ba" => "bahia",
				"ce" => "ceara",
				"df" => "federal district",
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

			class << self
				def process_fields(fields)

					unless fields[:city].nil?
						fields[:city] = process_text(fields[:city]) 
						fields[:city_ascii] = process_ascii(fields[:city])
						@states.each{|abbr, state|
							if(fields[:city_ascii].match(/[- ,\/]\s?(#{abbr}|#{state})\s?(\.|brasil)?$/i) != nil)
								# byebug
								fields[:state] = abbr
								fields[:city].gsub!(/[- ,\/]\s?(#{abbr}|#{state})(\s|\.|brasil)?$/i, "")
								fields[:city_ascii].gsub!(/[- ,\/]\s?(#{abbr}|#{state})\s?(\.|brasil)?$/i, "")
								break
							end
						}
					end

					fields[:state] = process_text(fields[:state]) unless fields[:state].nil?
					
					unless fields[:country].nil?
						fields[:country] = process_text(fields[:country]) 
						fields[:country_ascii] = process_ascii(fields[:country])
					end

					fields
				end

				def process_text(text)
					# TODO remover caracteres espciais ($;-&)
					text = text.tr(
						"ÀÁÂÃÄÅĀĂĄÇĆĈĊČÐĎĐÈÉÊËĒĔĖĘĚĜĞĠĢĤĦÌÍÎÏĨĪĬĮİĴĵĶĹĻĽĿŁÑŃŅŇŊÒÓÔÕÖØŌŎŐŔŖŘŚŜŞŠŢŤŦÙÚÛÜŨŪŬŮŰŲŴÝŶŸŹŻŽ",
						"àáâãäåāăąçćĉċčðďđèéêëēĕėęěĝğġģĥħìíîïĩīĭįıJjķĺļľŀłñńņňŋòóôõöøōŏőŕŗřśŝşšţťŧùúûüũūŭůűųŵýŷYźżž"
					)
					text = text.downcase
					text.gsub!(/\s+/, " ")
					text.gsub!(/^\s/, "")
					text.gsub!(/\s$/, "")
					text.gsub!(/[~`]/, "")
					text.gsub!(/-\s+capital/, "")
					text.gsub!(/[()]/, " ")
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
					return @states[state]
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

			def get_distinct_locations()
				@location_dump[:locations].where(country: 'Brasil', kind_course: 'birth').order(:country, :state, :city).distinct(:country, :state, :city).all
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
				@location_dump[:locations].where(id16: id16, kind_course: 'birth').all
			end

			def get_work(id16)
				@location_dump[:locations].where(id16: id16, kind_course: 'work').all
			end
		
			def get_degrees(id16)
				@location_dump[:locations].where("id16 = '#{id16}' and kind_course != 'birth' and kind_course != 'work'").all
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
				place
				# insert_location(place)
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

		end


		class LocationGeoNames

			def initialize()
				@con = ConnectionDB.new
				@location_dump = @con.get_location_dump
				@geonames = @con.get_geoname
				@cities_br = @con.get_cities_br
			end

			def get_latitude(location)
				# print "#{location[:city]}, #{location[:state]}, #{location[:country]}\n"
				if (location[:city].nil? or location[:city] == '') # and location[:uf].nil? and location[:country].nil? and location[:country_abbr].nil?
					return nil
				end
				geoname = @geonames[:geoname].where(Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(location[:city_ascii]))).all
		 
				if geoname.size == 1
					create_place_geoname(geoname.first)
				elsif geoname.size > 1
					if (location[:country].nil? or location[:country] == '')
						return nil
					end
					# puts " #######{location[:country]} "
					country = @location_dump[:countries].where(name_pt: location[:country]).all[0]
					country = @location_dump[:countries].where(name_ascii_pt: location[:country]).all[0] if country.nil?
					country = @location_dump[:countries].where(name_en: location[:country]).all[0] if country.nil?
					byebug if country.nil?
					geocountry = @geonames[:countryinfo].where(Sequel.ilike(:name, country[:name_en])).all[0]
					countrycode = geocountry[:iso_alpha2]

					result = @geonames[:geoname].where(
						Sequel.ilike(:asciiname, @geonames[:geoname].escape_like(location[:city_ascii])),
						Sequel.ilike(:country, countrycode)
					).all
					if result.size == 1
						create_place_geoname(result[0])
					elsif result.size > 1 and location[:country] == "brasil"
						if (location[:state].nil? or location[:state] == '')
							return nil
						end
						statename = Util.state_br(location[:state])
						state = @geonames[:admin1codes].where(Sequel.ilike(:countrycode, countrycode), Sequel.ilike(:alt_name_english, statename)).all[0]
						byebug if state.nil?
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
					geoname = @cities_br[:munic].where(nome_ascii: location[:city_ascii]).all
					return nil if geoname == []
					# TODO
					# byebug if geoname.size > 1
					create_place_munic(geoname.first)
				end
			end

			def create_place_munic(geoname)
				place = {}
				# byebug
				place[:city] = geoname[:nome] 
				place[:city_ascii] = geoname[:nome_ascii]
				place[:state] = Util.state_br(geoname[:uf])
				place[:state_ascii] = geoname[:uf] 
				place[:country] = 'brazil'
				place[:country_ascii] = 'brazil'
				place[:country_abbr] = 'BR'
				place[:latitude] = geoname[:latitude].to_f
				place[:longitude] = geoname[:longitude].to_f
				
				place = Util.process_fields(place)
			end

			def create_place_geoname(geoname)
				place = {}
				state = @geonames[:admin1codes].where(countrycode: geoname[:country], admin1_code: geoname[:admin1]).all[0]
				country = @geonames[:countryinfo].where(iso_alpha2: geoname[:country]).first
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
				
				place = Util.process_fields(place)
			end

		end

		class ConnectionDB
			def initialize()
				@geonames = Sequel.connect('postgres://postgres:postgres@192.168.56.101/geonames')
				@location_dump = Sequel.connect('postgres://postgres:postgres@192.168.56.101/latteslocationdumpdoutorado')
				@cities_br = Sequel.connect('postgres://postgres:postgres@192.168.56.101/munic')
			end

			def get_geoname
				@geonames
			end

			def get_location_dump
				@location_dump
			end

			def get_cities_br
				@cities_br
			end
		end

end
