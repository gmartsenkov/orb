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

CREATE TABLE USER_AVATAR(
	id SERIAL PRIMARY KEY,
	user_id INT,
	avatar_url TEXT,
	created_at timestamp,
	updated_at timestamp
);

CREATE TABLE POSTS(
	id SERIAL PRIMARY KEY,
	user_id INT,
	content TEXT,
	created_at timestamp,
	updated_at timestamp
);
