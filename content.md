## Geração dos modelos
```
rails generate model location city:string city_ascii:string uf:string country:string country_ascii:string country_abbr:string latitude:float longitude:float
rails generate model person id16:string location:references
rails generate model university name:string abbr:string location:references
rails generate model degree name:string year:integer university:references person:references

rails destroy model location
rails destroy model person
rails destroy model university
rails destroy model degree
```
