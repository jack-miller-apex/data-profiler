--- Inventory Stratification ---

DECLARE @ProjectNumber NVARCHAR(50) = ?,
        @RangeSize INT = 10,
        @UOM NVARCHAR(20) = ?;

DECLARE @RangeCutoff INT = @RangeSize * 10;

DECLARE @PeriodsOfInventory INT = (
    SELECT TOP (1) APPROX_COUNT_DISTINCT(id.Period)
    FROM OutputTables_Prod.InventoryData id
        LEFT JOIN OutputTables_Prod.ItemMaster im
        ON id.ProjectNumber_SKU = im.ProjectNumber_SKU
    WHERE im.ProjectNumber = @ProjectNumber
);

With tbl as (
    SELECT q.SKU, MAX(q.Velocity) as [Velocity], ROUND(SUM(q.Quantity) / CAST(@PeriodsOfInventory as Float), 2) as [Avg Quantity],
        CASE 
            WHEN AVG(q.Quantity) = 0 THEN '0'
            WHEN AVG(q.Quantity) = 1 THEN '1'
            WHEN AVG(q.Quantity) = 2 THEN '2'
            WHEN AVG(q.Quantity) <= 5 THEN '3-5'
            WHEN AVG(q.Quantity) <= 10 THEN '6-10'
            WHEN AVG(q.Quantity) <= 20 THEN '11-20'
            WHEN AVG(q.Quantity) <= 50 THEN '21-50'
            WHEN AVG(q.Quantity) <= 100 THEN '51-100'
            ELSE '101+'
        END as [Range],
        CASE 
            WHEN AVG(q.Quantity) = 0 THEN 0
            WHEN AVG(q.Quantity) = 1 THEN 1
            WHEN AVG(q.Quantity) = 2 THEN 2
            WHEN AVG(q.Quantity) <= 5 THEN 5
            WHEN AVG(q.Quantity) <= 10 THEN 10
            WHEN AVG(q.Quantity) <= 20 THEN 20
            WHEN AVG(q.Quantity) <= 50 THEN 50
            WHEN AVG(q.Quantity) <= 100 THEN 100
            ELSE 101
        END as [Range Max]
    FROM
        (SELECT id.[Period], im.SKU, MAX(im.Velocity) as [Velocity], SUM(id.Quantity) as Quantity
        FROM OutputTables_Prod.InventoryData id
            INNER JOIN OutputTables_Prod.ItemMaster im
            ON id.ProjectNumber_SKU = im.ProjectNumber_SKU
        WHERE im.ProjectNumber = @ProjectNumber AND id.UnitOfMeasure = @UOM
        GROUP BY id.[Period], im.SKU) q
    GROUP BY q.SKU
)


SELECT @ProjectNumber as [Project Number], @UOM as [Unit of Measure], Velocity, MAX(tbl.[Range Max]) as [Range Max], tbl.[Range], COUNT(tbl.SKU) as SKUs, ROUND(SUM(tbl.[Avg Quantity]), 0) as [Avg Total Quantity]
FROM tbl
GROUP BY tbl.Velocity, tbl.[Range]
ORDER BY tbl.Velocity, [Range Max] ASC
