## Geração dos modelos
```
rails generate model location city:string city_ascii:string state:string country:string country_ascii:string country_abbr:string latitude:float longitude:float
rails generate model instituition name:string abbr:string location:references
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