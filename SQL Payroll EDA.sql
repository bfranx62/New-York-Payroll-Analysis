USE payroll;

CREATE TABLE IF NOT EXISTS payroll (
    worker_id VARCHAR(255) PRIMARY KEY,
    fiscal_year DATE NOT NULL,
    agency_name VARCHAR(255) NOT NULL,
    agency_start_date DATE NOT NULL,
    work_location_borough VARCHAR(255) NOT NULL,
    title_description VARCHAR(255) NOT NULL,
    leave_status_as_of_june_30 VARCHAR(255) NOT NULL,
    base_salary DECIMAL(6,2) NOT NULL,
    pay_basis VARCHAR(255) NOT NULL,
    regular_hours DECIMAL(4,1) NOT NULL,
    regular_gross_paid DECIMAL(6,2) NOT NULL,
    ot_hours DECIMAL(4,1) NOT NULL,
    total_ot_paid DECIMAL(6,2) NOT NULL,
    total_other_pay DECIMAL(6,2) NOT NULL,
    converted_salary DECIMAL(6,2) NOT NULL,
    total_pay DECIMAL(6,2) NOT NULL);

ALTER TABLE payroll
MODIFY base_salary DECIMAL(8,2),
MODIFY regular_gross_paid DECIMAL(8,2),
MODIFY total_ot_paid DECIMAL(8,2),
MODIFY total_other_pay DECIMAL(8,2),
MODIFY converted_salary DECIMAL(8,2),
MODIFY total_pay DECIMAL(8,2),
MODIFY regular_hours DECIMAL(8,2),
MODIFY ot_hours DECIMAL(8,2);

-- Step 1: Add the new column
ALTER TABLE payroll
ADD COLUMN true_index VARCHAR(255) NOT NULL;

-- Step 2: Drop the existing primary key and modify worker_id
ALTER TABLE payroll
DROP PRIMARY KEY,
MODIFY COLUMN worker_id VARCHAR(255);

-- Step 3: Set the new_column as the new primary key
ALTER TABLE payroll
ADD PRIMARY KEY (true_index);

ALTER TABLE payroll
MODIFY COLUMN true_index INT;

USE payroll;

SELECT * FROM payroll;

SELECT fiscal_year, COUNT(fiscal_year)
FROM payroll
GROUP BY fiscal_year
ORDER BY fiscal_year ASC;
# So there SEEMS to be a general upward trend, but this may need to be analyzed visually

SELECT COUNT(DISTINCT(agency_name))
FROM payroll;

# CREATE TABLE agency_employees (
#     agency_name VARCHAR(255),
#     fiscal_year INT,
#     employee_count INT
# );

# INSERT INTO agency_changes (agency_name, fiscal_year, agency_count)
# SELECT agency_name, fiscal_year, COUNT(*) as agency_count
# FROM payroll;


SELECT agency_name, fiscal_year, agency_count, agency_count - LAG(agency_count, 1) OVER (PARTITION BY agency_name ORDER BY fiscal_year) AS change_from_prev
FROM agency_changes;

SELECT agency_name, AVG(change_from_prev) AS ave_change
FROM
	(
		SELECT agency_name, fiscal_year, agency_count, agency_count - LAG(agency_count, 1) OVER (PARTITION BY agency_name ORDER BY fiscal_year) AS change_from_prev
		FROM agency_changes
	) AS changes
GROUP BY agency_name
HAVING AVG(change_from_prev) > 100;
# All of these agencies have grown by an average of more than 100 people per year over the reported 10 years. 

SELECT agency_name, AVG(change_from_prev) AS ave_change
FROM
	(
		SELECT agency_name, fiscal_year, agency_count, agency_count - LAG(agency_count, 1) OVER (PARTITION BY agency_name ORDER BY fiscal_year) AS change_from_prev
		FROM agency_changes
	) AS changes
GROUP BY agency_name
HAVING AVG(change_from_prev) < -1;
# All of these organizations have experienced an average loss of employees of the reported 10 years. 

SELECT agency_name, AVG(change_from_prev) AS ave_change
FROM
	(
		SELECT agency_name, fiscal_year, agency_count, agency_count - LAG(agency_count, 1) OVER (PARTITION BY agency_name ORDER BY fiscal_year) AS change_from_prev
		FROM agency_changes
	) AS changes
GROUP BY agency_name
HAVING AVG(change_from_prev) < -100;
# These organizations have experienced an average loss of more than 100 employees per year over the last decade. 

SELECT agency_name, fiscal_year, agency_count, agency_count - LAG(agency_count, 1) OVER (PARTITION BY agency_name ORDER BY fiscal_year) AS change_from_prev
FROM agency_changes
WHERE agency_name = 'BOARD OF ELECTION POLL WORKERS';
# There are surges during election years, then drops during off years (big surprise). Theres a big average downward trend of about 400 ppl per year, though. 

SELECT agency_name, SUM(ot_hours) as agency_ot, SUM(total_ot_paid) as agency_ot_pay
FROM payroll
WHERE fiscal_year = 2014
GROUP BY agency_name
ORDER BY SUM(total_ot_paid) DESC
LIMIT 20;

# CREATE TABLE ot_hours (
#     agency_name VARCHAR(255),
#     fiscal_year INT,
#     agency_ot DECIMAL(10,2),
#     agency_ot_pay DECIMAL(11,2)
# );

# INSERT INTO ot_hours (agency_name, fiscal_year, agency_ot, agency_ot_pay)
# SELECT agency_name, fiscal_year, SUM(ot_hours) as agency_ot, SUM(total_ot_paid) as agency_ot_pay
# FROM payroll
# GROUP BY agency_name, fiscal_year;

SELECT *
FROM ot_hours
WHERE agency_ot > 1920; 
# These are all the agencies that, at any point, had enough overtime hours in 1 year that they could have used at least one extra full-time person on staff. 

SELECT *, agency_ot/1920 as staff_needed, agency_ot_pay/(agency_ot/1920) as avail_salary_per_needed
FROM ot_hours
WHERE agency_ot/1920 > 1
ORDER BY staff_needed DESC;

SELECT ot.agency_name, 
	   ot.fiscal_year, 
       ac.agency_count, 
       ot.agency_ot/1920 as staff_needed,
       LEAD(ac.agency_count, 1) OVER (PARTITION BY ac.agency_name ORDER BY ac.fiscal_year) - ac.agency_count AS staff_hired,
       (LEAD(ac.agency_count, 1) OVER (PARTITION BY ac.agency_name ORDER BY ac.fiscal_year) - ac.agency_count) - (ot.agency_ot/1920) as difference
FROM ot_hours as ot
JOIN agency_changes as ac
ON ot.agency_name = ac.agency_name AND ot.fiscal_year = ac.fiscal_year
WHERE ot.agency_ot/1920 > 1 AND 
	  ot.fiscal_year != 2023 
ORDER BY ABS(difference) DESC;

		