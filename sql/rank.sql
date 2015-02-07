DROP TABLE IF EXISTS language_ranks;
CREATE TABLE language_ranks AS
SELECT t1.*, t1.rank::FLOAT / t2.count_users * 100 AS top
FROM (
SELECT LANGUAGE, country, city, sum(stars) + (1.0 - 1.0/count(repositories.id)) AS score, row_number() OVER (PARTITION BY repositories.language, users.city ORDER BY (sum(stars) + (1.0 - 1.0/count(repositories.id))) DESC) AS rank, count(repositories.id) AS repository_count, sum(stars) AS stars_count, users.id AS user_id
FROM repositories
INNER JOIN users ON users.login = repositories.user_id
WHERE repositories.language IS NOT NULL AND users.organization=FALSE
GROUP BY repositories.language, city, country, users.id
) t1
INNER JOIN (
SELECT count(DISTINCT user_id) AS count_users, repositories.language, city, country
FROM repositories
INNER JOIN users ON repositories.user_id = users.login
WHERE repositories.language IS NOT NULL AND users.organization=FALSE
GROUP BY repositories.language, country, city
) t2
ON t1.language = t2.language AND (t1.city = t2.city OR (t1.city IS NULL AND t2.city IS NULL)) AND (t1.country = t2.country OR (t1.country IS NULL AND t2.country IS NULL));

CREATE INDEX language_ranks_user_id ON language_ranks USING btree (user_id);
CREATE INDEX language_ranks_city ON language_ranks USING btree (LANGUAGE, rank, city, country);