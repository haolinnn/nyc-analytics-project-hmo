-- Results dimension for restaurant health inspections
WITH results_data AS (
    SELECT DISTINCT
        CAST(score AS INT64) AS score, -- score to int
        grade
    FROM {{ source('staging', 'source_restaurant_health_inspections') }}
    WHERE score IS NOT NULL OR grade IS NOT NULL
),

results_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'score',
            'grade'
        ]) }} AS results_key,

        score,
        grade

    FROM results_data
)

SELECT * FROM results_dimension