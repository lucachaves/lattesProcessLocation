## Geração dos modelos
```
rails generate model location city:string city_ascii:string state:string country:string country_ascii:string country_abbr:string latitude:float longitude:float
rails generate model instituition name:string name_ascii:string abbr:string location:references
rails generate model person id16:string location:references instituition:references
rails generate model degree name:string start_year:integer end_year:integer instituition:references person:references

rails destroy model location
rails destroy model person
rails destroy model instituition
rails destroy model degree
```
# SELECT name_ascii, count(name_ascii)
#   FROM instituitions group by name_ascii order by 2 desc;

# SELECT DISTINCT place, count(place)
#   FROM locations group by place having count(place) > 0 order by 2 desc;


```
require 'progress_bar'

def process_downcase(text)
	return nil if text.nil?
	text = text.tr(
		"ÀÁÂÃÄÅĀĂĄÇĆĈĊČÐĎĐÈÉÊËĒĔĖĘĚĜĞĠĢĤĦÌÍÎÏĨĪĬĮİĴĵĶĹĻĽĿŁÑŃŅŇŊÒÓÔÕÖØŌŎŐŔŖŘŚŜŞŠŢŤŦÙÚÛÜŨŪŬŮŰŲŴÝŶŸŹŻŽ",
		"àáâãäåāăąçćĉċčðďđèéêëēĕėęěĝğġģĥħìíîïĩīĭįıJjķĺļľŀłñńņňŋòóôõöøōŏőŕŗřśŝşšţťŧùúûüũūŭůűųŵýŷYźżž"
	)
	text.downcase
end

ip = "192.168.56.101"
@location_dump = Sequel.connect("postgres://postgres:postgres@#{ip}/latteslocationdumpdoutorado")
cities = @location_dump[:cities].all
bar = ProgressBar.new(cities.size)
cities.each{|city|
	bar.increment!
	@location_dump[:cities].where('id =?', city[:id]).update(
		city: process_downcase(city[:city]), 
		state: process_downcase(city[:state]), 
		country: process_downcase(city[:country]),
		country_code1: process_downcase(city[:country_code1])
	)
}
```

Curved point-to-point “route maps”
curved line
directional curved line topojson

https://github.com/dkahle/ggmap
https://www.facebook.com/note.php?note_id=469716398919
http://flowingdata.com/2011/05/11/how-to-map-connections-with-great-circles/
http://paulbutler.org/archives/visualizing-facebook-friends/
http://dsgeek.com/2013/06/08/DrawingArcsonMaps.html

Gallery
http://cartodb.com/gallery/
http://cartodb.com/case-studies/flights-over-queens/
http://cartodb.com/gallery/twitter-superbowl/
http://cartodb.com/gallery/antieviction-mapping/
http://michaelminn.com/linux/mmqgis/
http://en.wikipedia.org/wiki/Chart
geochart
https://developers.google.com/chart/interactive/docs/gallery/geochart
http://en.wikipedia.org/wiki/Choropleth_map
http://en.wikipedia.org/wiki/Heat_map
http://en.wikipedia.org/wiki/Cartogram

TOOLS
http://oedb.org/ilibrarian/do-it-yourself-gis-20-free-tools-data-sources-for-creating-data-maps/
http://schoolofdata.org/2013/11/09/web-mapping/

Fusion Table
http://www.smalldatajournalism.com/projects/one-offs/mapping-with-fusion-tables/

Google Mpas
jquery.curved.line
http://curved_lines.overfx.net/
http://stackoverflow.com/questions/20321006/curved-line-between-two-near-points-in-google-maps

QGIS
categorized
http://qgis.spatialthoughts.com/2012/02/tutorial-styling-vector-data-in-qgis.html
MMQGIS
http://michaelminn.com/linux/mmqgis/
http://plugins.qgis.org/plugins/mmqgis/
FlowMapper
http://plugins.qgis.org/plugins/FlowMapper/
http://gis.stackexchange.com/questions/85394/flow-mapping-lines-by-magnitude
https://www.youtube.com/watch?v=5zBM97n9GEw
Flow Trace
https://github.com/boesiii/flowtrace
Heat Map
https://www.youtube.com/watch?v=AqAImLJ1O1g
https://www.youtube.com/watch?v=h-zX67ewqC4
Choropleth map
https://www.youtube.com/watch?v=iM06P7Wq9jQ

https://github.com/nextgis/joinlines
https://github.com/dgoedkoop/joinmultiplelines
https://github.com/jogc/multiline-join
https://github.com/peterahlstrom/PointConnector
https://github.com/chiatt/pointstopaths
https://launchpad.net/points2one
https://github.com/peterahlstrom/PointConnector
https://github.com/geo-data/qgis-quick-draw

PostGis
http://gis.stackexchange.com/questions/5204/curved-point-to-point-route-maps
http://anitagraser.com/2011/08/20/visualizing-global-connections/
http://postgis.org/documentation/manual-svn/ST_CurveToLine.html

Armchart
http://www.amcharts.com/
http://www.amcharts.com/javascript-maps/

FlowMapper
http://www.csiss.org/clearinghouse/FlowMapper/


# DEGREES
SELECT 
  people.id16, 
  degrees.name, 
  instituitions.name_ascii, 
  instituitions.abbr, 
  degrees.start_year, 
  degrees.end_year, 
  locations.city_ascii, 
  locations.state, 
  locations.country_ascii, 
  locations.latitude, 
  locations.longitude
FROM 
  public.degrees, 
  public.instituitions, 
  public.locations
WHERE 
  degrees.instituition_id = instituitions.id AND
  instituitions.location_id = locations.id;

# WORKS
SELECT 
  people.id16, 
  instituitions.name_ascii, 
  instituitions.abbr, 
  locations.city_ascii, 
  locations.state, 
  locations.country_ascii, 
  locations.latitude, 
  locations.longitude
FROM 
  public.people, 
  public.instituitions, 
  public.locations
WHERE 
  people.instituition_id = instituitions.id AND
  instituitions.location_id = locations.id;

# BIRTH
SELECT 
  people.id16, 
  locations.city_ascii, 
  locations.state, 
  locations.country_ascii, 
  locations.latitude, 
  locations.longitude
FROM 
  public.people, 
  public.locations
WHERE 
  people.location_id = locations.id;
