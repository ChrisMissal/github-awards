# Github-awards

Github-awards gives your rankings on Github by language and by location (city, country and worldwide) based on the number of stars of your repos.

In order to calculate you ranking on Github we need to :
- Get all github users with their location
- Geocode their location
- Get all github repositories with language and number of stars 

With this informations we are able to compute your ranking for a given language in a given city.

## Step 1 : Get all users and repositories

There are over 10 Millions users and over 15 Millions repositories, you cannot just use the get single element API from github for each user and repos.

However the github list api returns 100 results at a time with basic informations :
- [get-all-users](https://developer.github.com/v3/users/#get-all-users)
- [list-all-public-repositories](https://developer.github.com/v3/repos/#list-all-public-repositories)

With this you can get up to 500k user / repo per hour : this is enough to get the entire list of users and repositories with basic informations (username, repo name, etc).

Rake task are :

``` rake user:crawl_users ```

``` rake repo:crawl_repos ```

Now we need to get detailed informations such as location, language, number of stars.


## Step 2 : Use Google Big Query to get details about active users and repositories 

> GitHub Archive is a project to record the public GitHub timeline, archive it, and make it easily accessible for further analysis.

The Github Archive dataset is public, Google Big Query can be used to find details about users and repositories.

- Request for repositories :

[users.sql](https://github.com/vdaubry/github-awards-api/blob/master/sql/GoogleBigQuery/users.sql)

- Request for users :

[repos.sql](https://github.com/vdaubry/github-awards-api/blob/master/sql/GoogleBigQuery/repos.sql)

We can then download the results as JSON, parse the result, and fill missing informations about users and repos

Rake task are :

``` rake redis:parse_users ```

``` rake redis:parse_repos ```

We now have users location, and repositories language and number of stars. In order to get country and world rank we need to geocode user locations


## Step 3 : Geocoding user locations

Location on github profile is a plein text field, there are about 1 million location to geocode. A solution is to use a combination of :
- [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/)
- [Open Street Map API](http://wiki.openstreetmap.org/wiki/Nominatim)

Rake task is :

``` rake user:geocode_locations ```

We now have all informations we need to compute ranking.

## Step 4 : Compute rankings by language and by location (city/country/world)

In order to speed up queries based on user ranks, you can create a table with all rankings informations. Once we have all rankings informations on a table we can properly index it and query it in our web application with acceptable response time.

The query to create the language_rankings table can be found here :

[rank.sql](https://github.com/vdaubry/github-awards-api/blob/master/sql/rank.sql)


## Step 5 : VOILA ! Look for your ranking and have fun :)


Next steps :

- Automating data update
- Improve UI
