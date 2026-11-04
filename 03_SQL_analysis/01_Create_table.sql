-- Creating a new table for analysis of shopping data from Amazon

CREATE TABLE shopping_analysis (
    session_id VARCHAR(50),
    user_id VARCHAR(50),
    session_date DATE,
    prime_member_status VARCHAR(30),
    device_type VARCHAR(50),
    traffic_source VARCHAR(100),
    session_duration_mins NUMERIC(10,2),
    items_in_cart INTEGER,
    total_cart_value NUMERIC(12,2),
    drop_off_stage VARCHAR(50),
    data_quality_flag VARCHAR(50),
    outlier_analysis VARCHAR(100),
    customer_segment VARCHAR(100)
);


-- Setting date style to month-day-year format for consistancy in date representation
SET datestyle = 'ISO, DMY';


-- Importing cleaned data from csv file into the shopping_analysis table
COPY shopping_analysis 
FROM 'C:\Amazon_data_analysis\01_data\02_Cleaned_data\prime_cart_sessions_cleaned.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- Query to check the total number of records impoted into the shopping_analysis table.
SELECT COUNT(*) AS total_records
FROM public.shopping_analysis;


