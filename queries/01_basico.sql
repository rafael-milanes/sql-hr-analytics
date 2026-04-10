-- ============================================================
-- NIVEL BÁSICO — HR Analytics Employee Attrition
-- Funciones: SELECT, DISTINCT, LIKE, IN, BETWEEN, NOT IN,
--            COUNT, SUM, AVG, MIN, MAX, ROUND,
--            CASE WHEN, GROUP BY, ORDER BY, HAVING,
--            COALESCE, NULLIF, CAST, IS NULL, IS NOT NULL
-- ============================================================

-- ------------------------------------------------------------
-- Q01. Selección y exploración con DISTINCT
-- Función: DISTINCT, ORDER BY
-- ¿Qué combinaciones únicas de departamento, rol y estado civil existen?
-- ------------------------------------------------------------
SELECT DISTINCT
    Department,
    JobRole,
    MaritalStatus
FROM employee
ORDER BY Department, JobRole;


-- ------------------------------------------------------------
-- Q02. Filtrar con LIKE y wildcards
-- Función: LIKE, OR, %
-- ¿Qué empleados tienen roles de Manager o Engineer?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    JobRole,
    Department
FROM employee
WHERE JobRole LIKE '%Manager%'
   OR JobRole LIKE '%Engineer%'
ORDER BY JobRole;


-- ------------------------------------------------------------
-- Q03. Filtrar con IN y NOT IN
-- Función: IN, NOT IN, AND
-- ¿Empleados de Sales y HR que no son managers?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    JobRole,
    Salary
FROM employee
WHERE Department IN ('Sales', 'Human Resources')
  AND JobRole NOT IN ('Manager', 'HR Manager')
ORDER BY Department, Salary DESC;


-- ------------------------------------------------------------
-- Q04. Filtrar con BETWEEN
-- Función: BETWEEN, AND
-- ¿Empleados entre 30-40 años con salario 80K-150K contratados desde 2015?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Age,
    Salary,
    Department,
    HireDate
FROM employee
WHERE Age BETWEEN 30 AND 40
  AND Salary BETWEEN 80000 AND 150000
  AND HireDate BETWEEN '2015-01-01' AND '2022-12-31'
ORDER BY Salary DESC;


-- ------------------------------------------------------------
-- Q05. COUNT, SUM, AVG, MIN, MAX y ROUND
-- Función: Todas las funciones de agregación sobre la empresa
-- ¿Cuáles son las métricas globales de la empresa?
-- ------------------------------------------------------------
SELECT
    COUNT(*)              AS total_empleados,
    SUM(Salary)           AS masa_salarial,
    ROUND(AVG(Salary), 0) AS salario_promedio,
    MIN(Salary)           AS salario_minimo,
    MAX(Salary)           AS salario_maximo,
    ROUND(AVG(Age), 1)    AS edad_promedio,
    MIN(Age)              AS edad_minima,
    MAX(Age)              AS edad_maxima
FROM employee;


-- ------------------------------------------------------------
-- Q06. Agregación por grupo: salario por departamento
-- Función: GROUP BY, AVG, MIN, MAX, SUM, COUNT
-- ¿Cuál es el resumen salarial por departamento?
-- ------------------------------------------------------------
SELECT
    Department,
    COUNT(*)              AS total_empleados,
    ROUND(AVG(Salary), 0) AS salario_promedio,
    MIN(Salary)           AS salario_minimo,
    MAX(Salary)           AS salario_maximo,
    SUM(Salary)           AS masa_salarial
FROM employee
GROUP BY Department
ORDER BY salario_promedio DESC;


-- ------------------------------------------------------------
-- Q07. Tasa de rotación con SUM condicional
-- Función: SUM(CASE WHEN), ROUND, GROUP BY
-- ¿Cuál es la tasa de rotación por departamento?
-- ------------------------------------------------------------
SELECT
    Department,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct
FROM employee
GROUP BY Department
ORDER BY tasa_rotacion_pct DESC;


-- ------------------------------------------------------------
-- Q08. HAVING: filtrar grupos después de agregar
-- Función: HAVING con múltiples condiciones
-- ¿Qué JobRoles tienen más de 50 empleados y salario promedio > 60K?
-- ------------------------------------------------------------
SELECT
    JobRole,
    COUNT(*) AS total,
    ROUND(AVG(Salary), 0) AS salario_promedio,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct
FROM employee
GROUP BY JobRole
HAVING COUNT(*) > 50
   AND AVG(Salary) > 60000
ORDER BY tasa_rotacion_pct DESC;


-- ------------------------------------------------------------
-- Q09. Segmentación por rango de edad y rotación
-- Función: CASE WHEN con rangos numéricos, GROUP BY segmento
-- ¿Qué rango de edad tiene mayor tasa de rotación?
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN Age < 25              THEN '< 25'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS rango_edad,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct
FROM employee
GROUP BY rango_edad
ORDER BY rango_edad;


-- ------------------------------------------------------------
-- Q10. Segmentación de salario en bandas
-- Función: CASE WHEN con rangos, MIN para ORDER BY correcto
-- ¿Cómo se distribuyen los empleados por banda salarial?
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN Salary < 50000                  THEN 'Menos de 50K'
        WHEN Salary BETWEEN 50000 AND 79999  THEN '50K - 79K'
        WHEN Salary BETWEEN 80000 AND 109999 THEN '80K - 109K'
        WHEN Salary BETWEEN 110000 AND 139999 THEN '110K - 139K'
        ELSE '140K+'
    END AS banda_salarial,
    COUNT(*) AS empleados,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron
FROM employee
GROUP BY banda_salarial
ORDER BY MIN(Salary);


-- ------------------------------------------------------------
-- Q11. CASE WHEN con múltiples columnas: perfil de riesgo simple
-- Función: CASE WHEN evaluando varias columnas con AND/OR
-- ¿Qué nivel de riesgo tiene cada empleado según overtime y viajes?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    OverTime,
    YearsSinceLastPromotion,
    BusinessTravel,
    CASE
        WHEN OverTime = 'Yes'
         AND YearsSinceLastPromotion >= 5
         AND BusinessTravel = 'Frequent Traveller' THEN 'Riesgo Alto'
        WHEN OverTime = 'Yes'
         AND YearsSinceLastPromotion >= 3           THEN 'Riesgo Medio'
        WHEN OverTime = 'No'
         AND YearsSinceLastPromotion < 2            THEN 'Riesgo Bajo'
        ELSE 'Sin clasificar'
    END AS nivel_riesgo,
    Attrition
FROM employee
ORDER BY nivel_riesgo, Attrition
LIMIT 30;


-- ------------------------------------------------------------
-- Q12. IS NULL e IS NOT NULL
-- Función: Auditoría de nulos por columna clave
-- ¿Cuántos valores nulos hay en las columnas principales?
-- ------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS total_filas,
    COUNT(EmployeeID)                                           AS con_id,
    SUM(CASE WHEN EmployeeID   IS NULL THEN 1 ELSE 0 END)       AS nulos_id,
    SUM(CASE WHEN Department   IS NULL THEN 1 ELSE 0 END)       AS nulos_department,
    SUM(CASE WHEN Salary       IS NULL THEN 1 ELSE 0 END)       AS nulos_salary,
    SUM(CASE WHEN HireDate     IS NULL THEN 1 ELSE 0 END)       AS nulos_hiredate
FROM employee;


-- ------------------------------------------------------------
-- Q13. COALESCE: reemplazar nulos con un valor por defecto
-- Función: COALESCE(col, valor_default)
-- ¿Cómo se ven los datos con nulos reemplazados?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName                AS nombre,
    COALESCE(Department, 'Sin departamento')    AS department,
    COALESCE(Salary, 0)                         AS salary,
    COALESCE(YearsSinceLastPromotion, 0)        AS anos_sin_promocion,
    COALESCE(OverTime, 'No registrado')         AS overtime
FROM employee
ORDER BY EmployeeID
LIMIT 10;


-- ------------------------------------------------------------
-- Q14. NULLIF: convertir un valor específico a NULL
-- Función: NULLIF(a, b) para evitar división por cero
-- ¿Cómo evitar errores de división por cero en tasas?
-- ------------------------------------------------------------
SELECT
    Department,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0), 1
    ) AS tasa_rotacion_pct
FROM employee
GROUP BY Department
ORDER BY tasa_rotacion_pct DESC;


-- ------------------------------------------------------------
-- Q15. CAST: convertir tipos de datos
-- Función: CAST(valor AS REAL) para división decimal correcta
-- ¿Qué diferencia hay entre división entera y decimal?
-- ------------------------------------------------------------
SELECT
    Department,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    -- Sin CAST: división entera puede dar 0
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) AS tasa_sin_cast,
    -- Con CAST: división decimal correcta
    ROUND(
        CAST(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS REAL)
        / COUNT(*) * 100, 1
    ) AS tasa_con_cast_pct
FROM employee
GROUP BY Department;


-- ------------------------------------------------------------
-- Q16. Empleados con muchos años en la empresa sin promoción
-- Función: WHERE con múltiples condiciones AND
-- ¿Qué empleados llevan 8+ años sin una promoción significativa?
-- ------------------------------------------------------------
SELECT
    EmployeeID,
    FirstName || ' ' || LastName AS nombre,
    Department,
    JobRole,
    YearsAtCompany,
    YearsSinceLastPromotion,
    Salary,
    Attrition
FROM employee
WHERE YearsAtCompany >= 8
  AND YearsSinceLastPromotion >= 7
ORDER BY YearsSinceLastPromotion DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q17. Distribución porcentual de género por departamento
-- Función: GROUP BY doble, COUNT, porcentaje con OVER PARTITION BY
-- ¿Cuál es la distribución de género en cada departamento?
-- ------------------------------------------------------------
SELECT
    Department,
    Gender,
    COUNT(*) AS total,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Department), 1
    ) AS pct_en_depto
FROM employee
GROUP BY Department, Gender
ORDER BY Department, Gender;


-- ------------------------------------------------------------
-- Q18. Impacto del overtime en la rotación con múltiples métricas
-- Función: COUNT, SUM, AVG, ROUND, GROUP BY — query resumen
-- ¿Cómo afecta el overtime al perfil y rotación del empleado?
-- ------------------------------------------------------------
SELECT
    OverTime,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS tasa_rotacion_pct,
    ROUND(AVG(Salary), 0)         AS salario_promedio,
    ROUND(AVG(Age), 1)            AS edad_promedio,
    ROUND(AVG(YearsAtCompany), 1) AS anos_empresa_promedio
FROM employee
GROUP BY OverTime
ORDER BY tasa_rotacion_pct DESC;
