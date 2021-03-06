module UtilHelper

	class Util
		@states = {
			"ac" => "acre",
			"al" => "alagoas",
			"ap" => "amapa",
			"am" => "amazonas",
			"ba" => "bahia",
			"ce" => "ceara",
			"df" => "distrito federal",
			"es" => "espirito santo",
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
							fields[:state] = abbr
							fields[:city].gsub!(/[- ,\/]\s?(#{abbr}|#{state})(\s|\.|brasil)?$/i, "")
							fields[:city_ascii].gsub!(/[- ,\/]\s?(#{abbr}|#{state})\s?(\.|brasil)?$/i, "")
							break
						end
					}
				end
			end

			def clean_city(city)
				# city.gsub!(/-\s+capital/, "")
			end

			def clean_uni(uni)
				# uni = "univesidade de sao paulo" if uni.include? "univesidade de sao paulo"
				# uni = "univesidade de sao paulo" if uni.include? "usp"
			end

			def clean_text(text)
				# TODO remover caracteres espciais ($;-&)
				# remover de, da(s), do(s) 
				text.gsub!(/[\~\`\'\´\"\.\-\/\,\(\)]/, " ")
				text.gsub!(/\s+/, " ")
				text.gsub!(/^\s/, "")
				text.gsub!(/\s$/, "")
				text
			end
			
			def process_downcase(text)
				text = text.tr(
					"ÀÁÂÃÄÅĀĂĄÇĆĈĊČÐĎĐÈÉÊËĒĔĖĘĚĜĞĠĢĤĦÌÍÎÏĨĪĬĮİĴĵĶĹĻĽĿŁÑŃŅŇŊÒÓÔÕÖØŌŎŐŔŖŘŚŜŞŠŢŤŦÙÚÛÜŨŪŬŮŰŲŴÝŶŸŹŻŽ",
					"àáâãäåāăąçćĉċčðďđèéêëēĕėęěĝğġģĥħìíîïĩīĭįıJjķĺļľŀłñńņňŋòóôõöøōŏőŕŗřśŝşšţťŧùúûüũūŭůűųŵýŷYźżž"
				)
				text.downcase
			end

			def process_ascii(text)
				text = clean_text(text)
				text = text.tr(
					"ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
					"AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
				)
				text.downcase
			end

			def state_br(state)
				return @states[state]
			end

			def state_code_br(state)
				return @states.key(state)
			end

		end
	end	

end
