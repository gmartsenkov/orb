DROP DATABASE IF EXISTS orb_test;
CREATE DATABASE orb_test;

\connect orb_test

CREATE TABLE USERS(
	id SERIAL PRIMARY KEY,
	name TEXT,
	email TEXT,
	age INT,
	created_at timestamp,
	updated_at timestamp
);
