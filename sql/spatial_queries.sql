-- London Spatial Data Analysis
-- SpatiaLite query examples reconstructed from the tasks documented in the portfolio report.
-- These are not copied from the original coursework SQL because the report contains the
-- outputs and task descriptions, but not the original query text.
-- Table and geometry-column names may need to be adjusted to match the original database.

-- 1. Borough summary / extreme spatial values
-- The report includes borough area, density and north/south/east/west extents.
SELECT
    NAME AS borough_name,
    IN_OUT AS region,
    ST_Area(geometry) / 1000000.0 AS area_sq_km,
    Pop / (ST_Area(geometry) / 1000000.0) AS population_density,
    ST_MaxY(geometry) AS north,
    ST_MinY(geometry) AS south,
    ST_MaxX(geometry) AS east,
    ST_MinX(geometry) AS west
FROM london_boroughs;


-- 2. Count Underground stations by borough
-- Spatial join between station points and borough polygons.
SELECT
    b.NAME AS borough_name,
    COUNT(s.ROWID) AS number_of_tube_stations
FROM london_boroughs AS b
LEFT JOIN underground_stations AS s
    ON ST_Within(s.geometry, b.geometry)
GROUP BY b.NAME
ORDER BY number_of_tube_stations DESC;


-- 3. Motorways intersecting London boroughs
SELECT
    m.ROAD_NAME AS motorway,
    b.NAME AS borough_name,
    b.IN_OUT AS region
FROM motorways AS m
JOIN london_boroughs AS b
    ON ST_Intersects(m.geometry, b.geometry)
ORDER BY motorway, borough_name;


-- 4. Underground stations within 1 km of motorways
SELECT
    m.ROAD_NAME AS motorway,
    s.NAME AS station,
    s.LINE AS line,
    ST_Distance(s.geometry, m.geometry) AS distance_metres
FROM underground_stations AS s
JOIN motorways AS m
    ON ST_Distance(s.geometry, m.geometry) <= 1000
ORDER BY motorway, distance_metres;


-- 5. Create 1 km motorway buffers
SELECT
    ROAD_NAME,
    ST_Buffer(geometry, 1000) AS buffer_1km
FROM motorways;


-- 6. Create an outer motorway buffer up to 2.5 km
SELECT
    ROAD_NAME,
    ST_Difference(
        ST_Buffer(geometry, 2500),
        ST_Buffer(geometry, 1000)
    ) AS buffer_1km_to_2_5km
FROM motorways;


-- 7. GP surgery accessibility to nearest Underground station
-- The report describes a distance-matrix analysis in Haringey.
SELECT
    g.NAME AS gp_surgery,
    s.NAME AS station,
    ST_Distance(g.geometry, s.geometry) AS distance_metres
FROM gp_surgeries AS g
CROSS JOIN underground_stations AS s
WHERE g.borough = 'Haringey'
ORDER BY gp_surgery, distance_metres;


-- 8. Nearest Underground station for each GP surgery
WITH distances AS (
    SELECT
        g.ROWID AS gp_id,
        g.NAME AS gp_surgery,
        s.NAME AS station,
        ST_Distance(g.geometry, s.geometry) AS distance_metres
    FROM gp_surgeries AS g
    CROSS JOIN underground_stations AS s
    WHERE g.borough = 'Haringey'
)
SELECT
    gp_surgery,
    station,
    MIN(distance_metres) AS nearest_station_distance_metres
FROM distances
GROUP BY gp_id, gp_surgery;
