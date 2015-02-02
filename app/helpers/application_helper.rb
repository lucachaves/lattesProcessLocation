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
			# id16 = "1123365855931365"
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
			end
		end

		class LocationLattesDump

			def initialize()
				@location_dump = Sequel.connect('postgres://postgres:postgres@192.168.56.101/latteslocationdump')
				@geo = LocationGeoNames.new
				# process_code_country()
				# byebug
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

			def process_code_country
				ids = get_ids()
				geoname = @geo.get_connection()
				ids.each{|id|
					location = @location_dump[:locations].where(id: id).first
					unless location[:codecountry].nil?
						country = geoname[:countryinfo].where(iso_alpha3: location[:codecountry]).first
						puts location[:codecountry]
						# byebug
						# puts country[:iso_alpha2]
						@location_dump[:locations].where(id: id).update(codecountry: country[:iso_alpha2])
					else
						country = @location_dump[:countries].where(name_pt: Util.process_text(location[:country])).first
						unless country.nil?
							country = geoname[:countryinfo].where("lower(name) = '#{country[:name_en]}'").first
							@location_dump[:locations].where(id: id).update(codecountry: country[:iso_alpha2])
						end
					end
				}
			end

			def create_location(place)
				place = Util.process_fields(place)
				place[:latitude] = nil
				place[:longitude] = nil
				result = @geo.get_latitude(place)
				place = result unless result.nil?
				# byebug
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
				@geonames = Sequel.connect('postgres://postgres:postgres@192.168.56.101/geonames')
			end

			def get_connection()
				@geonames
			end

			def get_latitude(location)
				place = {}
				geo = @geonames[:geoname].where("lower(asciiname) = '#{location[:city_ascii]}'").all
				
				if geo.size == 1
					geoname = geo.first 
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

					return place
				end

				# country = @geonames[:countryinfo].where(iso_alpha2: location[:country]).all[0]
				# geo = @geonames[:geoname].where("lower(asciiname) = '#{location[:city_ascii]}' AND lower(country) = '#{location[:city_ascii]}'").all
				# TODO if result > 1 comparar state ou country
				# 'saint martin d'heres'

				# if 
					
				# else
					nil
				# end
			end

		end

		class LocationBrCities

			def initialize()
				@citiesbr = Sequel.connect('postgres://postgres:postgres@192.168.56.101/mc-munic')
			end

			def get_locations()
				@citiesbr[:munic].all
			end

		end

end
