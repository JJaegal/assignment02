/*
  Which bus stop has the largest population within 800 meters? As a rough
  estimation, consider any block group that intersects the buffer as being part
  of the 800 meter buffer.
*/

WITH
septa_bus_stop_blockgroups AS (
    SELECT
        stops.stop_id,
        '1500000US' || bg.geoid AS geoid
    FROM septa.bus_stops AS stops
    INNER JOIN census.blockgroups_2020 AS bg
        ON ST_DWithin(stops.geog, bg.geog, 800)
),

septa_bus_stop_surrounding_population AS ( -- noqa: LT08
    SELECT
        stops.stop_id,
        SUM(pop.total) AS estimated_pop_800m
    FROM septa_bus_stop_blockgroups AS stops
    INNER JOIN census.population_2020 AS pop USING (geoid)
    GROUP BY stops.stop_id
),

pop_with_row_number AS (
    SELECT
        stops.stop_name,
        pop.estimated_pop_800m / 2 AS estimated_pop_800m,
        stops.geog,
        ROW_NUMBER() OVER (PARTITION BY stops.stop_id ORDER BY pop.estimated_pop_800m DESC) AS rn -- noqa: LT05
    FROM septa_bus_stop_surrounding_population AS pop
    INNER JOIN septa.bus_stops AS stops USING (stop_id)
)

SELECT
    stop_name,
    estimated_pop_800m,
    ST_SetSRID(geog, 4326) AS geog
FROM pop_with_row_number
WHERE rn = 1
ORDER BY estimated_pop_800m DESC
LIMIT 8;
