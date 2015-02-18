# github-awards

Github-awards gives your rankings on Github by language and by location (city, country and worldwide) based on the number of stars of your repos.

In order to calculate you ranking on Github we need to :
- Get all github users with their location
- Geocode their location
- Get all github repositories with language and number of stars 

Then we are able to compute your ranking for a given language in a given city.

## Step 1 : Get all users and repositories

I used the github list api to get basic informations about users and repositories :
- [get-all-users](https://developer.github.com/v3/users/#get-all-users)
- [list-all-public-repositories](https://developer.github.com/v3/repos/#list-all-public-repositories)

The api returns up to 500k user / repo per hour : we get the entire list of users and repositories with basic informations (username, repo name, etc). Now we need to get detailed informations such as location, language, number of stars.

Rake task are :

``` rake user:crawl_users ```

``` rake repo:crawl_repos ```

## Step 2 : Use Google Big Query to get details about active users and repositories 

> GitHub Archive is a project to record the public GitHub timeline, archive it, and make it easily accessible for further analysis.

The Github Archive dataset is public, i used Google Big Query to get details about users and repositories.

- Request for repositories :

users.sql

- Request for users :

repos.sql

We can then download the results as JSON, parse the result, and fill missing informations about users and repos

Rake task are :

rake redis:parse_users
rake redis:parse_repos

We now have users location, and repositories language. In order to get country and world rank we need to geocode user locations


## Step 3 : Geocoding user locations

Location on github profile is a plein text field, there are about 1 million location to geocode. I used a combination of :
- [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/)
- [Open Street Map API](http://wiki.openstreetmap.org/wiki/Nominatim)

Rake task is :

rake user:geocode_locations

We now have all informations we need to compute ranking.

## Step 4 : Compute rankings by language and by location (city/country/world)

In order to speed up queries based on user ranks i created a table with all rankings informations. Once we have all rankings informations on a table we can properly index it and query it in our web application.

The query to create the language_rankings table can be found here :

``` sql/rank.sql ```


## Step 5 : VOILA ! Look for your ranking and have fun :)


Next steps :
Automating data update
Improve UI
