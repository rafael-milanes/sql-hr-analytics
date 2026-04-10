-- ============================================================
-- NIVEL AVANZADO — HR Analytics Employee Attrition
-- Funciones: RANK(), DENSE_RANK(), ROW_NUMBER(), NTILE(),
--            LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE(),
--            AVG/SUM/COUNT/MIN/MAX OVER PARTITION BY,
--            ROWS BETWEEN, PERCENT_RANK(), CUME_DIST(),
--            Acumulados para Pareto, Cohortes, Score de riesgo
--
-- Nota: ROLLUP no está soportado en SQLite.
-- En PostgreSQL o SQL Server usar: GROUP BY ROLLUP(col1, col2)
-- ============================================================

-- ============================================================
-- BLOQUE 1 — Funciones de ranking
-- ============================================================

-- ------------------------------------------------------------
-- Q01. RANK, DENSE_RANK y ROW_NUMBER
-- Diferencias clave:
--   RANK()       → mismo número a empates, salta el siguiente (1,1,3)
--   DENSE_RANK() → mismo número a empates, no salta (1,1,2)
--   ROW_NUMBER() → número único sin importar empates (1,2,3)
-- ¿Cómo se rankea el salario dentro de cada departamento?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    JobRole,
    Salary,
    RANK()       OVER (PARTITION BY Department ORDER BY Salary DESC) AS rank_salario,
    DENSE_RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS dense_rank_salario,
    ROW_NUMBER() OVER (PARTITION BY Department ORDER BY Salary DESC) AS row_num
FROM employee
ORDER BY Department, rank_salario
LIMIT 30;


-- ------------------------------------------------------------
-- Q02. NTILE: dividir empleados en cuartiles de salario
-- Función: NTILE(n) divide la partición en n grupos iguales
-- ¿Cómo varía la rotación según el cuartil salarial?
-- ------------------------------------------------------------
SELECT
    cuartil,
    COUNT(*) AS empleados,
    MIN(Salary) AS salario_min,
    MAX(Salary) AS salario_max,
    ROUND(AVG(Salary), 0) AS salario_promedio,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct
FROM (
    SELECT Salary, Attrition,
           NTILE(4) OVER (ORDER BY Salary DESC) AS cuartil
    FROM employee
)
GROUP BY cuartil
ORDER BY cuartil;


-- ------------------------------------------------------------
-- Q03. AVG/MIN/MAX/COUNT OVER PARTITION BY
-- Función: Window functions sin colapsar filas
-- ¿Cómo se compara el salario de cada empleado vs su departamento?
-- Diferencia clave vs GROUP BY: mantiene todas las filas
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    Salary,
    ROUND(AVG(Salary) OVER (PARTITION BY Department), 0) AS avg_depto,
    ROUND(MIN(Salary) OVER (PARTITION BY Department), 0) AS min_depto,
    ROUND(MAX(Salary) OVER (PARTITION BY Department), 0) AS max_depto,
    COUNT(*)      OVER (PARTITION BY Department)         AS total_depto,
    Salary - ROUND(AVG(Salary) OVER (PARTITION BY Department), 0) AS diferencia,
    ROUND(
        (Salary - AVG(Salary) OVER (PARTITION BY Department)) * 100.0
        / AVG(Salary) OVER (PARTITION BY Department), 1
    ) AS desviacion_pct
FROM employee
ORDER BY Department, desviacion_pct DESC
LIMIT 30;


-- ============================================================
-- BLOQUE 2 — Funciones de desplazamiento
-- ============================================================

-- ------------------------------------------------------------
-- Q04. LAG y LEAD: evolución de satisfacción entre evaluaciones
-- Función:
--   LAG(col, n)  → valor n filas ANTES dentro de la partición
--   LEAD(col, n) → valor n filas DESPUÉS dentro de la partición
-- ¿Mejoró o empeoró la satisfacción de cada empleado?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    ReviewDate,
    JobSatisfaction,
    LAG(JobSatisfaction)  OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS sat_anterior,
    LEAD(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS sat_siguiente,
    JobSatisfaction
        - LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS cambio,
    CASE
        WHEN JobSatisfaction > LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate)
             THEN 'Mejora'
        WHEN JobSatisfaction < LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate)
             THEN 'Baja'
        ELSE 'Sin cambio'
    END AS tendencia
FROM performance
ORDER BY EmployeeID, ReviewDate
LIMIT 30;


-- ------------------------------------------------------------
-- Q05. FIRST_VALUE y LAST_VALUE: primera y última evaluación
-- Función: FIRST_VALUE(), LAST_VALUE()
-- Importante: LAST_VALUE necesita ROWS BETWEEN UNBOUNDED PRECEDING
--             AND UNBOUNDED FOLLOWING para cubrir toda la partición
-- ¿Cómo cambió la satisfacción desde la primera a la última evaluación?
-- ------------------------------------------------------------
SELECT DISTINCT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName AS nombre,
    e.Attrition,
    FIRST_VALUE(p.JobSatisfaction) OVER (
        PARTITION BY p.EmployeeID ORDER BY p.ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS satisfaccion_inicial,
    LAST_VALUE(p.JobSatisfaction) OVER (
        PARTITION BY p.EmployeeID ORDER BY p.ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS satisfaccion_final,
    LAST_VALUE(p.JobSatisfaction) OVER (
        PARTITION BY p.EmployeeID ORDER BY p.ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) - FIRST_VALUE(p.JobSatisfaction) OVER (
        PARTITION BY p.EmployeeID ORDER BY p.ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS variacion_total
FROM employee e
INNER JOIN performance p ON e.EmployeeID = p.EmployeeID
ORDER BY variacion_total
LIMIT 20;


-- ------------------------------------------------------------
-- Q06. LAG con offset y valor por defecto
-- Función: LAG(col, n, default) — offset de 2 períodos
-- El tercer parámetro evita NULL en los primeros registros
-- ¿Cómo cambió la satisfacción vs hace 2 evaluaciones?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    ReviewDate,
    JobSatisfaction                                                          AS sat_actual,
    LAG(JobSatisfaction, 1, JobSatisfaction) OVER
        (PARTITION BY EmployeeID ORDER BY ReviewDate)                        AS sat_periodo_anterior,
    LAG(JobSatisfaction, 2, JobSatisfaction) OVER
        (PARTITION BY EmployeeID ORDER BY ReviewDate)                        AS sat_hace_2_periodos,
    JobSatisfaction - LAG(JobSatisfaction, 2, JobSatisfaction) OVER
        (PARTITION BY EmployeeID ORDER BY ReviewDate)                        AS cambio_2_periodos
FROM performance
ORDER BY EmployeeID, ReviewDate
LIMIT 30;


-- ============================================================
-- BLOQUE 3 — Ventanas con ROWS BETWEEN
-- ============================================================

-- ------------------------------------------------------------
-- Q07. Promedio móvil y acumulado de satisfacción
-- Función: AVG OVER ROWS BETWEEN N PRECEDING AND CURRENT ROW
--          AVG OVER ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- ¿Cuál es la tendencia de satisfacción de cada empleado?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    ReviewDate,
    JobSatisfaction,
    ROUND(AVG(JobSatisfaction) OVER (
        PARTITION BY EmployeeID
        ORDER BY ReviewDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS avg_movil_3,
    ROUND(AVG(JobSatisfaction) OVER (
        PARTITION BY EmployeeID
        ORDER BY ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS avg_acumulado,
    SUM(TrainingOpportunitiesTaken) OVER (
        PARTITION BY EmployeeID
        ORDER BY ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS capacitaciones_acumuladas
FROM performance
ORDER BY EmployeeID, ReviewDate
LIMIT 30;


-- ------------------------------------------------------------
-- Q08. MIN y MAX en ventana: rango histórico de satisfacción
-- Función: MIN/MAX OVER ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- ¿Está el empleado en su mejor o peor momento histórico?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    ReviewDate,
    JobSatisfaction,
    MIN(JobSatisfaction) OVER (
        PARTITION BY EmployeeID
        ORDER BY ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS min_historico,
    MAX(JobSatisfaction) OVER (
        PARTITION BY EmployeeID
        ORDER BY ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS max_historico,
    CASE
        WHEN JobSatisfaction = MIN(JobSatisfaction) OVER (
            PARTITION BY EmployeeID ORDER BY ReviewDate
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        THEN 'Mínimo histórico'
        WHEN JobSatisfaction = MAX(JobSatisfaction) OVER (
            PARTITION BY EmployeeID ORDER BY ReviewDate
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        THEN 'Máximo histórico'
        ELSE ''
    END AS nota
FROM performance
ORDER BY EmployeeID, ReviewDate
LIMIT 30;


-- ------------------------------------------------------------
-- Q09. COUNT OVER: evaluaciones acumuladas por empleado
-- Función: COUNT OVER ROWS BETWEEN, COUNT OVER sin restricción
-- ¿Cuántas evaluaciones lleva cada empleado en cada momento?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    ReviewDate,
    JobSatisfaction,
    COUNT(*) OVER (
        PARTITION BY EmployeeID
        ORDER BY ReviewDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS num_evaluacion_acumulada,
    COUNT(*) OVER (PARTITION BY EmployeeID) AS total_evaluaciones_empleado,
    COUNT(*) OVER ()                        AS total_evaluaciones_global
FROM performance
ORDER BY EmployeeID, ReviewDate
LIMIT 30;


-- ============================================================
-- BLOQUE 4 — Distribución estadística
-- ============================================================

-- ------------------------------------------------------------
-- Q10. PERCENT_RANK: posición percentil del salario
-- Función: PERCENT_RANK() — valor entre 0 y 1
-- Fórmula: (rank - 1) / (total_filas - 1)
-- Un valor de 0.9 = el empleado gana más que el 90% de su depto
-- ¿En qué percentil salarial está cada empleado?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    Salary,
    ROUND(PERCENT_RANK() OVER (PARTITION BY Department ORDER BY Salary) * 100, 1) AS percentil_en_depto,
    ROUND(PERCENT_RANK() OVER (ORDER BY Salary) * 100, 1)                         AS percentil_global
FROM employee
ORDER BY Department, Salary DESC
LIMIT 30;


-- ------------------------------------------------------------
-- Q11. CUME_DIST: distribución acumulada de salarios
-- Función: CUME_DIST() — proporción de filas <= valor actual
-- Diferencia vs PERCENT_RANK: incluye la fila actual en el numerador,
-- por lo que el último valor siempre es 1.0
-- ¿Qué proporción de empleados gana igual o menos que cada uno?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    Salary,
    ROUND(CUME_DIST() OVER (PARTITION BY Department ORDER BY Salary) * 100, 1) AS cume_dist_depto_pct,
    ROUND(CUME_DIST() OVER (ORDER BY Salary) * 100, 1)                         AS cume_dist_global_pct
FROM employee
ORDER BY Department, Salary
LIMIT 30;


-- ------------------------------------------------------------
-- Q12. Comparación PERCENT_RANK vs CUME_DIST vs NTILE
-- Las tres funciones de distribución juntas para comparar:
--   PERCENT_RANK → posición relativa, el primero es siempre 0
--   CUME_DIST    → proporción acumulada, el último es siempre 1
--   NTILE(100)   → percentil discreto, divide en 100 grupos iguales
-- ------------------------------------------------------------
SELECT
    Salary,
    Department,
    ROUND(PERCENT_RANK() OVER (ORDER BY Salary) * 100, 1) AS percent_rank_pct,
    ROUND(CUME_DIST()    OVER (ORDER BY Salary) * 100, 1) AS cume_dist_pct,
    NTILE(100)           OVER (ORDER BY Salary)           AS ntile_percentil
FROM employee
ORDER BY Salary
LIMIT 20;


-- ============================================================
-- BLOQUE 5 — Pareto y acumulados
-- ============================================================

-- ------------------------------------------------------------
-- Q13. Pareto de headcount por JobRole
-- Función: SUM acumulado OVER ORDER BY, porcentaje acumulado
-- ¿Qué JobRoles concentran el 80% del headcount? (Regla 80/20)
-- ------------------------------------------------------------
WITH conteo AS (
    SELECT JobRole, COUNT(*) AS total
    FROM employee
    GROUP BY JobRole
),
pareto AS (
    SELECT
        JobRole,
        total,
        SUM(total) OVER () AS gran_total,
        SUM(total) OVER (
            ORDER BY total DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS acumulado,
        ROUND(total * 100.0 / SUM(total) OVER (), 1) AS pct_individual,
        ROUND(
            SUM(total) OVER (
                ORDER BY total DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0 / SUM(total) OVER (), 1
        ) AS pct_acumulado
    FROM conteo
)
SELECT
    JobRole, total, pct_individual, acumulado, pct_acumulado,
    CASE WHEN pct_acumulado <= 80 THEN 'Top 80%' ELSE 'Cola 20%' END AS segmento_pareto
FROM pareto
ORDER BY total DESC;


-- ------------------------------------------------------------
-- Q14. Pareto de rotación: JobRoles que concentran el 80% de las bajas
-- Función: CTE + SUM acumulado + clasificación Pareto
-- ¿En qué roles se concentra el problema de attrition?
-- ------------------------------------------------------------
WITH rotacion AS (
    SELECT
        JobRole,
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS bajas
    FROM employee
    GROUP BY JobRole
),
pareto_rotacion AS (
    SELECT
        JobRole, bajas,
        SUM(bajas) OVER () AS total_bajas,
        SUM(bajas) OVER (
            ORDER BY bajas DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS acum_bajas,
        ROUND(bajas * 100.0 / SUM(bajas) OVER (), 1) AS pct_individual,
        ROUND(
            SUM(bajas) OVER (
                ORDER BY bajas DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0 / SUM(bajas) OVER (), 1
        ) AS pct_acumulado
    FROM rotacion
)
SELECT
    JobRole, bajas, pct_individual, pct_acumulado,
    CASE WHEN pct_acumulado <= 80 THEN 'Crítico (80%)' ELSE 'Resto' END AS clasificacion
FROM pareto_rotacion
ORDER BY bajas DESC;


-- ------------------------------------------------------------
-- Q15. Participación % de masa salarial por departamento con acumulado
-- Función: SUM OVER () sin partición para total global
-- ¿Qué departamentos concentran la mayor parte del costo salarial?
-- ------------------------------------------------------------
WITH masa AS (
    SELECT
        Department,
        SUM(Salary) AS masa_salarial,
        COUNT(*)    AS empleados
    FROM employee
    GROUP BY Department
)
SELECT
    Department,
    empleados,
    masa_salarial,
    ROUND(masa_salarial * 100.0 / SUM(masa_salarial) OVER (), 1) AS pct_masa_salarial,
    SUM(masa_salarial) OVER (
        ORDER BY masa_salarial DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_masa,
    ROUND(
        SUM(masa_salarial) OVER (
            ORDER BY masa_salarial DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 / SUM(masa_salarial) OVER (), 1
    ) AS pct_acumulado
FROM masa
ORDER BY masa_salarial DESC;


-- ============================================================
-- BLOQUE 6 — Análisis compuesto
-- ============================================================

-- ------------------------------------------------------------
-- Q16. Análisis de cohorte por año de contratación
-- Función: strftime para extraer año, SUM acumulado de headcount
-- ¿Las cohortes más antiguas tienen más rotación?
-- ------------------------------------------------------------
WITH cohorte AS (
    SELECT
        strftime('%Y', HireDate)                                      AS anio,
        COUNT(*)                                                       AS contratados,
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)            AS rotaron,
        ROUND(AVG(Salary), 0)                                          AS salario_promedio,
        ROUND(AVG(YearsAtCompany), 1)                                  AS anos_promedio
    FROM employee
    GROUP BY anio
)
SELECT
    anio,
    contratados,
    rotaron,
    ROUND(rotaron * 100.0 / contratados, 1)    AS tasa_rotacion_pct,
    salario_promedio,
    anos_promedio,
    SUM(contratados) OVER (
        ORDER BY anio
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS contratados_acum,
    ROUND(
        SUM(contratados) OVER (
            ORDER BY anio
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 / SUM(contratados) OVER (), 1
    ) AS pct_acum_headcount
FROM cohorte
ORDER BY anio;


-- ------------------------------------------------------------
-- Q17. Top 10% salarial con rating de manager bajo
-- Función: NTILE(10), CTE encadenado, JOIN triple
-- ¿Quiénes están bien pagados pero tienen evaluación de liderazgo deficiente?
-- ------------------------------------------------------------
WITH salario_ntile AS (
    SELECT
        EmployeeID, Department, Salary,
        NTILE(10) OVER (PARTITION BY Department ORDER BY Salary DESC) AS decil
    FROM employee
),
ultima_eval AS (
    SELECT EmployeeID, ManagerRating, ReviewDate
    FROM performance p
    WHERE ReviewDate = (
        SELECT MAX(p2.ReviewDate) FROM performance p2
        WHERE p2.EmployeeID = p.EmployeeID
    )
)
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName AS nombre,
    e.Department,
    e.JobRole,
    e.Salary,
    s.decil,
    ue.ManagerRating,
    r.RatingLevel,
    e.Attrition
FROM employee e
INNER JOIN salario_ntile s ON e.EmployeeID = s.EmployeeID
INNER JOIN ultima_eval  ue ON e.EmployeeID = ue.EmployeeID
INNER JOIN rating_level  r ON ue.ManagerRating = r.RatingID
WHERE s.decil = 1
  AND ue.ManagerRating <= 2
ORDER BY e.Department, e.Salary DESC;


-- ------------------------------------------------------------
-- Q18. Score de riesgo de rotación con ranking completo
-- Función: CTE múltiple, score ponderado, RANK, NTILE
-- ¿Quiénes son los empleados con mayor riesgo de rotación?
-- Útil como input para dashboard de alerta temprana en Power BI/Tableau
-- ------------------------------------------------------------
WITH avg_perf AS (
    SELECT
        EmployeeID,
        ROUND(AVG(JobSatisfaction), 2) AS avg_job_sat,
        ROUND(AVG(WorkLifeBalance), 2) AS avg_wlb,
        ROUND(AVG(ManagerRating), 2)   AS avg_mgr_rating
    FROM performance
    GROUP BY EmployeeID
),
score AS (
    SELECT
        e.EmployeeID,
        e.FirstName || ' ' || e.LastName AS nombre,
        e.Department,
        e.JobRole,
        e.Attrition,
        ap.avg_job_sat,
        ap.avg_wlb,
        ap.avg_mgr_rating,
        ROUND(
            (CASE WHEN e.OverTime = 'Yes'             THEN 20 ELSE 0 END)
          + (CASE WHEN e.YearsSinceLastPromotion >= 5 THEN 15 ELSE 0 END)
          + (CASE WHEN ap.avg_job_sat <= 2            THEN 25
                  WHEN ap.avg_job_sat <= 3            THEN 10 ELSE 0 END)
          + (CASE WHEN ap.avg_wlb <= 2               THEN 20
                  WHEN ap.avg_wlb <= 3               THEN 8  ELSE 0 END)
          + (CASE WHEN ap.avg_mgr_rating <= 2         THEN 20
                  WHEN ap.avg_mgr_rating <= 3         THEN 8  ELSE 0 END)
        , 0) AS score_riesgo
    FROM employee e
    INNER JOIN avg_perf ap ON e.EmployeeID = ap.EmployeeID
)
SELECT
    EmployeeID, nombre, Department, JobRole, Attrition,
    score_riesgo,
    RANK()   OVER (ORDER BY score_riesgo DESC)                         AS ranking_global,
    RANK()   OVER (PARTITION BY Department ORDER BY score_riesgo DESC) AS ranking_depto,
    NTILE(4) OVER (ORDER BY score_riesgo DESC)                         AS cuartil_riesgo
FROM score
ORDER BY score_riesgo DESC
LIMIT 30;
