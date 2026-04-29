{{ config(
    materialized='table'
) }}

WITH source AS (
    SELECT *
    FROM {{ source('raw_restaurant', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        CAST(objectid AS STRING) AS restaurant_app_id,
        TRIM(CAST(restaurant_name AS STRING)) AS restaurant_name,
        TRIM(CAST(legal_business_name AS STRING)) AS legal_business_name,
        TRIM(CAST(doing_business_as_dba AS STRING)) AS dba_name,
        CAST(bulding_number AS STRING) AS building_number,
        TRIM(CAST(street AS STRING)) AS street_name,
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) = 'BROOKLYN' THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) = 'QUEENS' THEN 'Queens'
            WHEN UPPER(TRIM(borough)) = 'BRONX' THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'STATEN IS') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,
        CASE WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING) ELSE NULL END AS zip_code,
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk,
        CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway,
        CURRENT_TIMESTAMP() AS _stg_loaded_at
    FROM source
    WHERE objectid IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned