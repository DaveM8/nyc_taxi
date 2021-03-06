/*

Set up all the geographical joins
Find out which  Election District ~ 5000 in NYC
and State Assembly District ~ 60 in NYC
The trips start and finish in.
This combined with the time of the pickups
I will try to maximise the amount of fair a driver
collects while minimising the number of hours worked

*/

-- turn the lat, lon co-ordinates into a geometry point
DROP TABLE ny_taxi_geom;
CREATE TABLE ny_taxi_geom AS
    SELECT
	SERIAL AS row_id
	, taxi.*
	,ST_SetSRID(ST_Point(pickup_longitude, pickup_latitude), 4326) AS pickup_geom
	,ST_SetSRID(ST_Point(dropoff_longitude, dropoff_latitude), 4326) AS dropoff_geom
    FROM ny_taxi AS taxi;
-- create indexs on thoses points
    CREATE INDEX ON "ny_taxi_geom" USING GIST ("pickup_geom");
    CREATE INDEX ON "ny_taxi_geom" USING GIST ("dropoff_geom");

    -- for each pickup and dropoff point
    -- find out which Election District and State Assembly District
    -- the fair staeted and finished in

CREATE TABLE ny_taxi_ad_pickup AS 
    SELECT
	taxi.*
	, ny_ad_pickup.assemdist AS pickup_ad_dist
	, ny_ad_dropoff.assemdist AS dropoff_ad_dist
	, ny_ed_pickup.electdist AS pickup_ed_dist
	, ny_ed_dropoff.electdist AS dropoff_ed_dist

    FROM ny_taxi_geom AS taxi
	LEFT
	JOIN nyad AS ny_ad_pickup
	ON ST_Contains(ny_ad_pickup.geom_nyad, taxi.pickup_geom)

	LEFT
	JOIN nyad AS ny_ad_dropoff
	ON ST_Contains(ny_ad_dropoff.geom_nyad, taxi.dropoff_geom)

	LEFT
	JOIN nyed AS ny_ed_pickup
	ON ST_Contains(ny_ed_pickup.geom_nyed, taxi.pickup_geom)

	LEFT
	JOIN nyed AS ny_ed_dropoff
	ON ST_Contains(ny_ed_dropoff.geom_nyed, taxi.dropoff_geom);

    -- only include rows where the total_amount == sum(all other compontens)
    -- some really expensive taxi rids ~ 900000 get removed by this
    -- also most on the rows removed have some negative values

CREATE TABLE ny_bad_rows AS
SELECT
    *
FROM  ny_taxi_ad_pickup
WHERE  total_amount <>  fare_amount + extra + mta_tax + tip_amount + tolls_amount +improvement_surcharge;

CREATE TABLE ny_good_rows AS
SELECT
    *
FROM  ny_taxi_ad_pickup
WHERE  total_amount = fare_amount + extra + mta_tax + tip_amount + tolls_amount +improvement_surcharge;

-- re run with the cleaned up dataset
    -- extract the month, day and hour from each pickup
    -- datetime
DROP TABLE ny_taxi_time;
    CREATE TABLE ny_taxi_time AS
SELECT
    taxi.*
    , EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour
    , TO_CHAR(pickup_datetime, 'D') AS pickup_day
    , EXTRACT(MONTH FROM pickup_datetime) AS pickup_month
FROM ny_good_rows taxi;

-- create a table with the average amount of fair etc
-- colected by trips starting en each AD, ED , Day Month, Hour
CREATE TABLE ny_taxi_pickup AS
SELECT
    pickup_ad_dist
    , pickup_ed_dist
    , pickup_hour
    , pickup_day
    , pickup_month
    , AVG(total_amount) AS avg_total
    , SUM(total_amount) AS total_amt
    , AVG(tip_amount) AS avg_tip
    , SUM(tip_amount) AS total_tip
    , COUNT(*) AS num_trips
FROM ny_taxi_time AS taxi
GROUP BY
    pickup_ad_dist
    , pickup_ed_dist
    , pickup_hour
    , pickup_day
    , pickup_month;

-- get per ride data 
DROP TABLE ny_taxi_ride_ed;
CREATE TABLE ny_taxi_ride_ed AS
SELECT
    DISTINCT
    pickup_ad_dist
    , pickup_ed_dist
    , pickup_hour
    , pickup_day
    , CAST(total_amt AS NUMERIC) / num_trips AS avg_amt_per_trip
    , CAST(total_tip AS NUMERIC) / num_trips AS avg_tip_per_trip
    , num_trips
FROM
(
SELECT
    pickup_ad_dist
    , pickup_ed_dist
    , pickup_hour
    , pickup_day
    , SUM(total_amount) AS total_amt
    , SUM(tip_amount) AS total_tip
    , COUNT(*) AS num_trips
FROM ny_taxi_time AS taxi
GROUP BY
    pickup_ad_dist
    , pickup_ed_dist
    , pickup_hour
    , pickup_day
    )sub;

GROUP BY
    pickup_ed_dist
    , geom_nyed

-- tables with geom to create maps :(sadly these tables take up alot
-- of disk space ~ 6GB ):
DROP TABLE hourly_fair_per_ed;
CREATE TABLE hourly_fair_per_ed AS
SELECT
    pickup_ed_dist
    , geom_nyed
    , AVG(hourly_fair) AS avg_amt_per_hour
    , AVG(hourly_tip)  AS avg_tip_per_hour
    , AVG(num_hourly_fair) AS avg_num_fair_per_hour
FROM
(
SELECT
    pickup_ed_dist
    , geom_nyed
    , EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour
    , SUM(total_amount) AS hourly_fair
    , SUM(tip_amount) AS hourly_tip
    , COUNT(*) AS num_hourly_fair
FROM nyed AS ed
    LEFT
    JOIN ny_good_rows AS pickup
    ON ed.electdist = pickup.pickup_ed_dist
GROUP BY pickup_ed_dist
    , geom_nyed
    , pickup_hour
    )sub
GROUP BY
    pickup_ed_dist
    , geom_nyed

-- I have run out of disk space so I cannot run this qurey :(
CREATE TABLE hourly_fair_per_ad AS
SELECT
    pickup_ad_dist
    , geom_nyad
    , AVG(hourly_fair) AS avg_amt_per_hour
    , AVG(hourly_tip)  AS avg_tip_per_hour
    , AVG(num_hourly_fair) AS avg_num_fair_per_hour
FROM
(
SELECT
    pickup_ad_dist
    , geom_nyad
    , EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour
    , SUM(total_amount) AS hourly_fair
    , SUM(tip_amount) AS hourly_tip
    , COUNT(*) AS num_hourly_fair
FROM nyad AS ad
    LEFT
    JOIN ny_good_rows AS pickup
    ON ad.assemdist = pickup.pickup_ad_dist
GROUP BY pickup_ad_dist
    , geom_nyad
    , pickup_hour
    )sub
GROUP BY
    pickup_ad_dist
    , geom_nyadp;
