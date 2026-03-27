{{ config(
    materialized='table'
) }}

-- Clean and standardize NYC Open Restaurant Applications data
-- One row per restaurant application

WITH source AS (
    SELECT * 
    FROM {{ source('raw_restaurant', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
       
        * EXCEPT (
            objectid,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            borough,
            zip,
            street,
            bulding_number,
            latitude,
            longitude,
            time_of_submission
        ),

        -- Primary key
        CAST(objectid AS STRING) AS restaurant_app_id,

        -- Names
        TRIM(CAST(restaurant_name AS STRING)) AS restaurant_name,
        TRIM(CAST(legal_business_name AS STRING)) AS legal_business_name,
        TRIM(CAST(doing_business_as_dba AS STRING)) AS dba_name,

        -- Address
        CAST(bulding_number AS STRING) AS building_number,
        TRIM(CAST(street AS STRING)) AS street_name,

        -- Standardize borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) = 'BROOKLYN' THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) = 'QUEENS' THEN 'Queens'
            WHEN UPPER(TRIM(borough)) = 'BRONX' THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'STATEN IS') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Clean zip (only keep 5-digit zips)
        CASE
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        -- Coordinates
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Submission time
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- Flags
        CAST(approved_for_sidewalk_seating AS STRING) AS sidewalk_seating_flag,
        CAST(approved_for_roadway_seating AS STRING) AS roadway_seating_flag,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Basic filtering
    WHERE objectid IS NOT NULL

    -- Deduplicate: keep latest submission per objectid
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid 
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned