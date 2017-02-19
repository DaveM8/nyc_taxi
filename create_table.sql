-- load the full data set into postgres
DROP TABLE ny_taxi;
CREATE TABLE ny_taxi(
	vendorid INTEGER, 
	pickup_datetime timestamp, 
	dropoff_datetime timestamp, 
	store_and_fwd_flag TEXT, 
	rate_code INTEGER, 
	pickup_longitude numeric, 
	pickup_latitude numeric, 
	dropoff_longitude numeric, 
	dropoff_latitude numeric, 
	passenger_count INTEGER, 
	trip_distance numeric, 
	fare_amount numeric, 
	extra numeric, 
	mta_tax numeric, 
	tip_amount numeric, 
	tolls_amount numeric, 
	ehail_fee numeric, 
	improvement_surcharge numeric,
	total_amount numeric, 
	payment_type INTEGER, 
	trip_type INTEGER
	);
COPY ny_taxi FROM '/home/postgres/new_york_taxi.csv' DELIMITER ',' CSV HEADER;

