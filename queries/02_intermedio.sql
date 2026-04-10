-- ============================================================
-- NIVEL INTERMEDIO — HR Analytics Employee Attrition
-- Funciones: INNER JOIN, LEFT JOIN, JOIN triple,
--            Subquery escalar, subquery correlacionada,
--            IN (subquery), EXISTS,
--            CTE simple, CTE doble, CTE triple encadenado,
--            UNION ALL, UNION, INTERSECT, EXCEPT,
--            UPPER, LOWER, LENGTH, TRIM, SUBSTR, REPLACE,
--            strftime
-- ============================================================

-- ============================================================
-- BLOQUE 1 — JOINs
-- ============================================================

-- ------------------------------------------------------------
-- Q01. INNER JOIN: satisfacción por departamento
-- Función: INNER JOIN, AVG, COUNT DISTINCT
-- ¿Cuál es el nivel de satisfacción promedio por departamento?
-- ------------------------------------------------------------
SELECT
    e.Department,
    ROUND(AVG(p.JobSatisfaction), 2)          AS avg_job_satisfaction,
    ROUND(AVG(p.EnvironmentSatisfaction), 2)  AS avg_env_satisfaction,
    ROUND(AVG(p.WorkLifeBalance), 2)          AS avg_wlb,
    COUNT(DISTINCT e.EmployeeID)              AS empleados_evaluados
FROM employee e
INNER JOIN performance p ON e.EmployeeID = p.EmployeeID
GROUP BY e.Department
ORDER BY avg_job_satisfaction DESC;


-- ------------------------------------------------------------
-- Q02. LEFT JOIN: detectar empleados sin evaluación
-- Función: LEFT JOIN, IS NULL
-- ¿Qué empleados no tienen ninguna evaluación registrada?
-- ------------------------------------------------------------
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName AS nombre,
    e.Department,
    e.HireDate,
    e.Attrition
FROM employee e
LEFT JOIN performance p ON e.EmployeeID = p.EmployeeID
WHERE p.EmployeeID IS NULL
ORDER BY e.HireDate;


-- ------------------------------------------------------------
-- Q03. JOIN con tabla de dimensión: nivel educativo y rotación
-- Función: INNER JOIN con catálogo, GROUP BY doble
-- ¿Cómo varía la rotación según el nivel educativo por departamento?
-- ------------------------------------------------------------
SELECT
    e.Department,
    el.EducationLevel,
    COUNT(*) AS total,
    SUM(CASE WHEN e.Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN e.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_pct
FROM employee e
INNER JOIN education_level el ON e.Education = el.EducationLevelID
GROUP BY e.Department, el.EducationLevel
ORDER BY e.Department, tasa_pct DESC;


-- ------------------------------------------------------------
-- Q04. JOIN triple con subquery correlacionada: última evaluación
-- Función: JOIN triple con alias, subquery MAX correlacionada
-- ¿Cuál fue la última evaluación de cada empleado con etiquetas?
-- ------------------------------------------------------------
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName AS nombre,
    e.Department,
    e.JobRole,
    p.ReviewDate                     AS ultima_evaluacion,
    p.ManagerRating,
    r.RatingLevel                    AS etiqueta_manager,
    p.SelfRating,
    r2.RatingLevel                   AS etiqueta_self
FROM employee e
INNER JOIN performance  p  ON e.EmployeeID    = p.EmployeeID
INNER JOIN rating_level r  ON p.ManagerRating = r.RatingID
INNER JOIN rating_level r2 ON p.SelfRating    = r2.RatingID
WHERE p.ReviewDate = (
    SELECT MAX(p2.ReviewDate)
    FROM performance p2
    WHERE p2.EmployeeID = e.EmployeeID
)
ORDER BY e.Department, p.ManagerRating
LIMIT 20;


-- ------------------------------------------------------------
-- Q05. JOIN con comparación entre columnas: brecha self vs manager
-- Función: JOIN, WHERE comparando columnas de la misma fila
-- ¿Dónde hay mayor brecha entre autoevaluación y rating del manager?
-- ------------------------------------------------------------
SELECT
    e.Department,
    e.JobRole,
    COUNT(*) AS casos,
    ROUND(AVG(p.SelfRating - p.ManagerRating), 2) AS brecha_promedio
FROM employee e
INNER JOIN performance p ON e.EmployeeID = p.EmployeeID
WHERE p.SelfRating > p.ManagerRating
GROUP BY e.Department, e.JobRole
ORDER BY casos DESC;


-- ============================================================
-- BLOQUE 2 — Subqueries
-- ============================================================

-- ------------------------------------------------------------
-- Q06. Subquery escalar en WHERE: salario sobre el promedio
-- Función: Subquery escalar, comparación dinámica
-- ¿Qué empleados ganan más que el promedio de la empresa?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    JobRole,
    Salary,
    ROUND(Salary - (SELECT AVG(Salary) FROM employee), 0) AS diferencia_vs_promedio
FROM employee
WHERE Salary > (SELECT AVG(Salary) FROM employee)
ORDER BY Salary DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q07. Subquery escalar en HAVING: JobRoles sobre promedio general
-- Función: Subquery escalar en HAVING
-- ¿Qué JobRoles tienen salario promedio sobre el promedio general?
-- ------------------------------------------------------------
SELECT
    JobRole,
    COUNT(*) AS empleados,
    ROUND(AVG(Salary), 0) AS salario_promedio
FROM employee
GROUP BY JobRole
HAVING AVG(Salary) > (SELECT AVG(Salary) FROM employee)
ORDER BY salario_promedio DESC;


-- ------------------------------------------------------------
-- Q08. Subquery con IN: empleados en departamentos con alta rotación
-- Función: IN (subquery), filtrado dinámico
-- ¿Qué empleados pertenecen a departamentos con rotación > 15%?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    JobRole,
    Salary,
    Attrition
FROM employee
WHERE Department IN (
    SELECT Department
    FROM employee
    GROUP BY Department
    HAVING ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1
    ) > 15
)
ORDER BY Department, Attrition DESC
LIMIT 30;


-- ------------------------------------------------------------
-- Q09. EXISTS: empleados con al menos una evaluación muy baja
-- Función: EXISTS, subquery correlacionada
-- ¿Qué empleados tuvieron alguna vez satisfacción mínima?
-- ------------------------------------------------------------
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName AS nombre,
    e.Department,
    e.JobRole,
    e.Attrition
FROM employee e
WHERE EXISTS (
    SELECT 1
    FROM performance p
    WHERE p.EmployeeID = e.EmployeeID
      AND p.JobSatisfaction = 1
)
ORDER BY e.Department
LIMIT 20;


-- ============================================================
-- BLOQUE 3 — CTEs
-- ============================================================

-- ------------------------------------------------------------
-- Q10. CTE simple: perfil del empleado que rota vs el que se queda
-- Función: WITH, GROUP BY Attrition, AVG múltiple
-- ¿Cuál es el retrato robot del empleado que rota?
-- ------------------------------------------------------------
WITH perfil AS (
    SELECT
        Attrition,
        ROUND(AVG(Age), 1)                     AS edad_promedio,
        ROUND(AVG(Salary), 0)                  AS salario_promedio,
        ROUND(AVG(YearsAtCompany), 1)          AS anos_empresa,
        ROUND(AVG(YearsSinceLastPromotion), 1) AS anos_sin_promocion,
        ROUND(AVG(YearsWithCurrManager), 1)    AS anos_con_manager,
        ROUND(AVG(CASE WHEN OverTime = 'Yes' THEN 1.0 ELSE 0 END) * 100, 1) AS pct_overtime
    FROM employee
    GROUP BY Attrition
)
SELECT * FROM perfil;


-- ------------------------------------------------------------
-- Q11. CTE doble: empleados con satisfacción bajo el promedio global
-- Función: CTE encadenado, HAVING con subquery del primer CTE
-- ¿Cuántos empleados con satisfacción baja terminaron rotando?
-- ------------------------------------------------------------
WITH avg_global AS (
    SELECT AVG(JobSatisfaction) AS media_global
    FROM performance
),
empleados_bajos AS (
    SELECT
        p.EmployeeID,
        AVG(p.JobSatisfaction) AS avg_satisfaccion
    FROM performance p
    GROUP BY p.EmployeeID
    HAVING AVG(p.JobSatisfaction) < (SELECT media_global FROM avg_global)
)
SELECT
    e.Attrition,
    COUNT(*)                           AS total,
    ROUND(AVG(eb.avg_satisfaccion), 2) AS satisfaccion_promedio
FROM empleados_bajos eb
INNER JOIN employee e ON eb.EmployeeID = e.EmployeeID
GROUP BY e.Attrition;


-- ------------------------------------------------------------
-- Q12. CTE con JOIN: capacitaciones y su efecto en la rotación
-- Función: CTE que pre-agrega, luego JOIN con tabla principal
-- ¿Las capacitaciones reducen la rotación?
-- ------------------------------------------------------------
WITH resumen_perf AS (
    SELECT
        EmployeeID,
        ROUND(AVG(JobSatisfaction), 2)  AS avg_satisfaccion,
        SUM(TrainingOpportunitiesTaken) AS total_capacitaciones
    FROM performance
    GROUP BY EmployeeID
)
SELECT
    CASE
        WHEN rp.total_capacitaciones = 0             THEN 'Sin capacitación'
        WHEN rp.total_capacitaciones BETWEEN 1 AND 5 THEN '1-5 capacitaciones'
        ELSE '6+ capacitaciones'
    END AS nivel_capacitacion,
    COUNT(*) AS empleados,
    ROUND(AVG(rp.avg_satisfaccion), 2) AS satisfaccion_promedio,
    SUM(CASE WHEN e.Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN e.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct
FROM employee e
INNER JOIN resumen_perf rp ON e.EmployeeID = rp.EmployeeID
GROUP BY nivel_capacitacion
ORDER BY tasa_rotacion_pct DESC;


-- ------------------------------------------------------------
-- Q13. CTE triple encadenado: score de riesgo y clasificación
-- Función: 3 CTEs en cadena, score ponderado, categorización final
-- ¿Cómo se distribuyen los empleados por categoría de riesgo?
-- ------------------------------------------------------------
WITH metricas AS (
    SELECT
        EmployeeID,
        ROUND(AVG(JobSatisfaction), 2) AS avg_sat,
        ROUND(AVG(WorkLifeBalance), 2) AS avg_wlb,
        ROUND(AVG(ManagerRating), 2)   AS avg_mgr
    FROM performance
    GROUP BY EmployeeID
),
score AS (
    SELECT
        e.EmployeeID,
        e.FirstName || ' ' || e.LastName AS nombre,
        e.Department,
        e.Attrition,
        (CASE WHEN e.OverTime = 'Yes'   THEN 20 ELSE 0 END
         + CASE WHEN m.avg_sat <= 2     THEN 25 WHEN m.avg_sat <= 3 THEN 10 ELSE 0 END
         + CASE WHEN m.avg_wlb <= 2     THEN 20 WHEN m.avg_wlb <= 3 THEN 8  ELSE 0 END
         + CASE WHEN m.avg_mgr <= 2     THEN 20 WHEN m.avg_mgr <= 3 THEN 8  ELSE 0 END
        ) AS score_riesgo
    FROM employee e
    INNER JOIN metricas m ON e.EmployeeID = m.EmployeeID
),
clasificado AS (
    SELECT *,
        CASE
            WHEN score_riesgo >= 60 THEN 'Riesgo Crítico'
            WHEN score_riesgo >= 35 THEN 'Riesgo Alto'
            WHEN score_riesgo >= 15 THEN 'Riesgo Medio'
            ELSE 'Riesgo Bajo'
        END AS categoria_riesgo
    FROM score
)
SELECT
    categoria_riesgo,
    COUNT(*) AS empleados,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct
FROM clasificado
GROUP BY categoria_riesgo
ORDER BY MIN(score_riesgo) DESC;


-- ============================================================
-- BLOQUE 4 — Operaciones de conjuntos
-- ============================================================

-- ------------------------------------------------------------
-- Q14. UNION ALL: perfil de rotados vs activos en una sola tabla
-- Función: UNION ALL — apila conservando duplicados
-- ¿Cómo se comparan métricas de rotados vs activos por rol?
-- Nota: UNION ALL es más rápido que UNION porque no elimina duplicados
-- ------------------------------------------------------------
SELECT
    'Rotó'   AS grupo,
    Department,
    JobRole,
    ROUND(AVG(Salary), 0)                  AS salario_promedio,
    ROUND(AVG(YearsAtCompany), 1)          AS anos_empresa,
    ROUND(AVG(YearsSinceLastPromotion), 1) AS anos_sin_promocion
FROM employee
WHERE Attrition = 'Yes'
GROUP BY Department, JobRole

UNION ALL

SELECT
    'Activo' AS grupo,
    Department,
    JobRole,
    ROUND(AVG(Salary), 0),
    ROUND(AVG(YearsAtCompany), 1),
    ROUND(AVG(YearsSinceLastPromotion), 1)
FROM employee
WHERE Attrition = 'No'
GROUP BY Department, JobRole

ORDER BY Department, JobRole, grupo;


-- ------------------------------------------------------------
-- Q15. UNION: lista única de empleados en condición de riesgo
-- Función: UNION — apila eliminando duplicados automáticamente
-- ¿Qué empleados cumplen al menos una condición de riesgo?
-- ------------------------------------------------------------
SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName AS nombre,
    e.Department,
    'Overtime + baja satisfacción'   AS condicion_riesgo
FROM employee e
INNER JOIN performance p ON e.EmployeeID = p.EmployeeID
WHERE e.OverTime = 'Yes'
  AND p.JobSatisfaction <= 2

UNION

SELECT
    e.EmployeeID,
    e.FirstName || ' ' || e.LastName,
    e.Department,
    'Sin promoción +5 años'
FROM employee e
WHERE e.YearsSinceLastPromotion >= 5

ORDER BY Department, nombre;


-- ------------------------------------------------------------
-- Q16. INTERSECT: empleados que cumplen AMBAS condiciones
-- Función: INTERSECT — solo filas presentes en los dos conjuntos
-- ¿Qué empleados tienen overtime + baja satisfacción Y sin promoción?
-- ------------------------------------------------------------
SELECT e.EmployeeID, e.FirstName || ' ' || e.LastName AS nombre, e.Department
FROM employee e
INNER JOIN performance p ON e.EmployeeID = p.EmployeeID
WHERE e.OverTime = 'Yes'
  AND p.JobSatisfaction <= 2

INTERSECT

SELECT e.EmployeeID, e.FirstName || ' ' || e.LastName, e.Department
FROM employee e
WHERE e.YearsSinceLastPromotion >= 5

ORDER BY Department, nombre;


-- ------------------------------------------------------------
-- Q17. EXCEPT: overtime y baja satisfacción, excluyendo sin promoción
-- Función: EXCEPT — filas del primer conjunto que no están en el segundo
-- ¿Qué empleados tienen solo el riesgo de overtime/satisfacción?
--
-- Resumen de operaciones de conjuntos:
-- UNION ALL  → Todo A + todo B        | Conserva duplicados
-- UNION      → Todo A + todo B        | Elimina duplicados
-- INTERSECT  → Solo lo que está en A y B | Elimina duplicados
-- EXCEPT     → Lo que está en A pero no en B | Elimina duplicados
-- ------------------------------------------------------------
SELECT e.EmployeeID, e.FirstName || ' ' || e.LastName AS nombre, e.Department
FROM employee e
INNER JOIN performance p ON e.EmployeeID = p.EmployeeID
WHERE e.OverTime = 'Yes'
  AND p.JobSatisfaction <= 2

EXCEPT

SELECT e.EmployeeID, e.FirstName || ' ' || e.LastName, e.Department
FROM employee e
WHERE e.YearsSinceLastPromotion >= 5

ORDER BY Department, nombre;


-- ============================================================
-- BLOQUE 5 — Funciones de texto y fecha
-- ============================================================

-- ------------------------------------------------------------
-- Q18. UPPER, LOWER, LENGTH, TRIM
-- Función: Funciones básicas de manipulación de texto
-- ¿Cómo normalizar y explorar columnas de texto?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName,
    LastName,
    UPPER(FirstName)                AS nombre_mayusculas,
    LOWER(LastName)                 AS apellido_minusculas,
    LENGTH(FirstName || LastName)   AS largo_nombre_completo,
    TRIM('  ' || FirstName || '  ') AS nombre_sin_espacios,
    UPPER(Department)               AS depto_mayusculas
FROM employee
LIMIT 10;


-- ------------------------------------------------------------
-- Q19. SUBSTR y REPLACE: extraer y transformar texto
-- Función: SUBSTR(texto, inicio, longitud), REPLACE(texto, buscar, reemplazar)
-- ¿Cómo extraer partes de un texto y reemplazar valores?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    SUBSTR(EmployeeID, 1, 4)                   AS prefijo_id,
    SUBSTR(EmployeeID, LENGTH(EmployeeID) - 3) AS sufijo_id,
    JobRole,
    REPLACE(JobRole, ' ', '_')                 AS job_role_slug,
    REPLACE(JobRole, 'Manager', 'Mgr')         AS job_role_corto
FROM employee
LIMIT 10;


-- ------------------------------------------------------------
-- Q20. strftime: extraer componentes de fecha y análisis temporal
-- Función: strftime('%Y/%m/%d/%w', fecha) — específico de SQLite
-- ¿Cuántas contrataciones hubo por año y mes?
-- Nota: En otros motores usar YEAR(), DATE_PART() o FORMAT()
-- ------------------------------------------------------------
SELECT
    strftime('%Y', HireDate) AS anio_contratacion,
    strftime('%m', HireDate) AS mes_contratacion,
    CASE strftime('%w', HireDate)
        WHEN '0' THEN 'Domingo'
        WHEN '1' THEN 'Lunes'
        WHEN '2' THEN 'Martes'
        WHEN '3' THEN 'Miércoles'
        WHEN '4' THEN 'Jueves'
        WHEN '5' THEN 'Viernes'
        WHEN '6' THEN 'Sábado'
    END AS dia_semana_contratacion,
    COUNT(*) AS contratados,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron
FROM employee
GROUP BY anio_contratacion, mes_contratacion
ORDER BY anio_contratacion, mes_contratacion;
