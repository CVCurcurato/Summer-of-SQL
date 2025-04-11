-- For the reader, this sequence of scripts is meant to help show not only how to solve this problem but also my thinking process.
-- There are faster ways to solve this problem but I wanted to include investigative steps as well.

-- Starting Clue
-- A crime has taken place and the detective needs your help. The detective gave you the crime scene report, but you somehow lost it. 
-- You vaguely remember that the crime was a ​murder​ that occurred sometime on ​Jan.15, 2018​ and that it took place in ​SQL City​. Start by retrieving the corresponding crime scene report from the police department’s database.

-- Step 1: This query retrieves the crime scene reports relevant to the only clue we have in the beginning
SELECT *
FROM crime_scene_report
WHERE type = "murder"
AND city = "SQL City"
AND date = 20180115

-- Reveals witnesses
-- Witness 1 Lives at the last house on "Northwestern Dr"
-- Witness 2 is named Annabel and lives somewhere on "Franklin Ave"


-- Step 2a: This query finds Witness 1
SELECT id, name, license_id, MAX(address_number) AS address_num, address_street_name, ssn
FROM person
WHERE address_street_name = "Northwestern Dr"

-- Witness 1 is named Morty Schapiro, details below
-- id	name	license_id	address_num	address_street_name	ssn
-- 14887	Morty Schapiro	118009	4919	Northwestern Dr	111564949

-- Step 2b: This query finds Witness 2
SELECT *
FROM person
WHERE name LIKE "Annabel%"
AND address_street_name = "Franklin Ave"

-- Witness 2 is named Annabel Miller, details below
-- id	name	license_id	address_number	address_street_name	ssn
-- 16371	Annabel Miller	490173	103	Franklin Ave	318771143

-- Step 3: Retrieve interview info
SELECT *
FROM interview
WHERE person_id = 16371
OR person_id = 14887

-- Reveals that Annabel saw the killer at her gym and that Morty recognized that he was a gold member with info on his bag and car plate
-- person_id	transcript
-- 14887	I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag. The membership number on the bag started with "48Z". Only gold members have those bags. The man got into a car with a plate that included "H42W".
-- 16371	I saw the murder happen, and I recognized the killer from my gym when I was working out last week on January the 9th.

-- Step 4a: Find out what time Annabel went to the gym on January 9th, 2018
SELECT id, person_id, name, check_in_date, check_in_time, check_out_time
FROM get_fit_now_member
LEFT JOIN get_fit_now_check_in
ON membership_id = id
WHERE name = "Annabel Miller"
AND check_in_date = 20180109

-- Annabel was present between 4 and 5pm (1600 - 1700)
-- id	person_id	name	check_in_date	check_in_time	check_out_time
-- 90081	16371	Annabel Miller	20180109	1600	1700

-- Step 4b: Find gym members that were present during the same time range as Annabel
SELECT id, person_id, name, check_in_date, check_in_time, check_out_time
FROM get_fit_now_member
LEFT JOIN get_fit_now_check_in
ON membership_id = id
WHERE membership_status = "gold"
AND check_in_date = 20180109
AND check_in_time <= 1600
AND check_out_time >= 1700
AND id LIKE "48Z%"
GROUP BY 1,2,3,4

-- Reveals Jeremy Bowers and Joe Germuska as likely suspects
-- id	person_id	name	check_in_date	check_in_time	check_out_time
-- 48Z55	67318	Jeremy Bowers	20180109	1530	1700
-- 48Z7A	28819	Joe Germuska	20180109	1600	1730
-- 90081	16371	Annabel Miller	20180109	1600	1700

-- Step 5a: Find suspect license info
SELECT *
FROM person
WHERE id = 28819
OR id = 67318

-- Result
-- id	    name	     license_id	address_number	address_street_name	ssn
-- 28819	Joe Germuska	173289	111	Fisk Rd	138909730
-- 67318	Jeremy Bowers	423327	530	Washington Pl, Apt 3A	871539279

-- Step 5b: Find car info with license info (join to include names and personal id)
SELECT name, p.id AS person_id, d.id, age, height, eye_color, hair_color, gender, plate_number, car_make, car_model 
FROM drivers_license AS d
JOIN person AS p
ON p.license_id = d.id
WHERE d.id = 173289
OR d.id = 423327
OR plate_number LIKE "%H42W%"
GROUP BY 1,2,3

-- ID match with Jeremy Bowers, suspect pool increased just in case
-- name	person_id	id	age	height	eye_color	hair_color	gender	plate_number	car_make	car_model
-- Tushar Chandra	51739	664760	21	71	black	black	male	4H42WR	Nissan	Altima
-- Jeremy Bowers	67318	423327	30	70	brown	brown	male	0H42W2	Chevrolet	Spark LS
-- Maxine Whitely	78193	183779	21	65	blue	blonde	female	H42W0X	Toyota	Prius


-- Step 6: Submit suspect Jeremy Bowers
INSERT INTO solution VALUES (1, 'Jeremy Bowers');    
SELECT value FROM solution;

-- Result
-- value
-- Congrats, you found the murderer! But wait, there's more... If you think you're up for a challenge, try querying the interview transcript of the murderer to find the real villain behind this crime.
-- If you feel especially confident in your SQL skills, try to complete this final step with no more than 2 queries. Use this same INSERT statement with your new suspect to check your answer.

-- Step 7: Query Jeremy Bowers transcript
SELECT *
FROM interview
WHERE person_id = 67318

-- Result
-- person_id	transcript
-- 67318	I was hired by a woman with a lot of money. I don't know her name but I know she's around 5'5" (65") or 5'7" (67"). She has red hair and she drives a Tesla Model S. I know that she attended the SQL Symphony Concert 3 times in December 2017.

-- Step 8a: Match person and car info
SELECT name, ssn, p.id AS person_id, d.id, age, height, eye_color, hair_color, gender, plate_number, car_make, car_model 
FROM drivers_license AS d
JOIN person AS p
ON p.license_id = d.id
WHERE car_make = 'Tesla'
AND car_model = 'Model S'
AND hair_color = 'red'
AND gender = 'female'
AND height >= 65
AND height <= 67
GROUP BY 1,2,3

-- name	ssn	person_id	id	age	height	eye_color	hair_color	gender	plate_number	car_make	car_model
-- Red Korb	961388910	78881	918773	48	65	black	red	female	917UU3	Tesla	Model S
-- Regina George	337169072	90700	291182	65	66	blue	red	female	08CM64	Tesla	Model S
-- Miranda Priestly	987756388	99716	202298	68	66	green	red	female	500123	Tesla	Model S

-- Step 8b: Check financial details for high income
SELECT name, I.ssn, annual_income
FROM income AS I
JOIN person AS P
ON P.ssn = I.ssn
WHERE I.ssn IN ('961388910', '337169072', '987756388')

-- name	ssn	annual_income
-- Red Korb	961388910	278000
-- Miranda Priestly	987756388	310000

-- Step 8c: Check facebook event checkins for December 2017
SELECT p.name, f.person_id, event_id, event_name, f.date
FROM facebook_event_checkin AS f
JOIN person AS p
ON p.id = f.person_id
WHERE p.name = 'Regina George'
OR p.name = 'Miranda Priestly'
AND event_name = 'SQL Symphony Concert'
AND CAST(f.date AS varchar) LIKE '201712%'

-- Result, Miranda Priestly visited, 3 times in December 2017
-- name	person_id	event_id	event_name	date
-- Miranda Priestly	99716	1143	SQL Symphony Concert	20171206
-- Miranda Priestly	99716	1143	SQL Symphony Concert	20171212
-- Miranda Priestly	99716	1143	SQL Symphony Concert	20171229
 
-- Step 9: Submit suspect Miranda Priestly
INSERT INTO solution VALUES (1, 'Miranda Priestly');    
SELECT value FROM solution;

-- Result
-- value
-- Congrats, you found the brains behind the murder! Everyone in SQL City hails you as the greatest SQL detective of all time. Time to break out the champagne!
