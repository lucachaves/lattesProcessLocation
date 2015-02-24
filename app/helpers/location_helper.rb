require "sequel"
require "progress_bar"
require "thread/pool"

module LocationHelper

	def process
		p = ProcessHelper::ProcessLocations.new
		p.process_locations
	end

end




