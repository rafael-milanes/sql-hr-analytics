# 🧠 SQL Practice — HR Analytics Employee Attrition

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/rafael-milanes/sql-hr-analytics/blob/main/setup.ipynb)
[![Dataset](https://img.shields.io/badge/Dataset-Kaggle-20BEFF?style=flat-square&logo=kaggle&logoColor=white)](https://www.kaggle.com/datasets/mahmoudemadabdallah/hr-analytics-employee-attrition-and-performance)
[![Motor](https://img.shields.io/badge/Motor-SQLite-003B57?style=flat-square&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Colab](https://img.shields.io/badge/Ejecutar%20en-Google%20Colab-F9AB00?style=flat-square&logo=googlecolab&logoColor=white)](https://colab.research.google.com)

---

## ¿De qué trata este proyecto?

Este repositorio está diseñado para practicar SQL desde nivel básico hasta avanzado sobre un dataset real de Recursos Humanos. El objetivo es responder preguntas de negocio concretas sobre rotación, satisfacción y desempeño de empleados, usando **SQLite en Google Colab** — sin instalar ninguna base de datos.

Incluye **56 queries organizadas en 3 niveles**, cada una con su explicación didáctica y contexto de negocio.

> Las queries están escritas en **SQLite**. Son 95% portables a PostgreSQL, SQL Server y BigQuery con ajustes menores de sintaxis.

---

## 🗂️ Modelo de datos

```
employee (1) ──── (N) performance
    │
    ├── Education ──────────────► education_level
    │         performance.JobSatisfaction       ──► satisfied_level
    │         performance.EnvironmentSatisfaction──► satisfied_level
    │         performance.WorkLifeBalance        ──► satisfied_level
    │         performance.ManagerRating          ──► rating_level
    │         performance.SelfRating             ──► rating_level
```

| Tabla | Filas | Descripción |
|---|---|---|
| `employee` | 1,470 | Datos demográficos, laborales y de rotación |
| `performance` | 6,709 | Evaluaciones periódicas (hasta 10 por empleado) |
| `education_level` | 5 | Catálogo: No Formal → Doctorate |
| `rating_level` | 5 | Catálogo: Unacceptable → Above and Beyond |
| `satisfied_level` | 5 | Catálogo: Very Dissatisfied → Very Satisfied |

---

## 📁 Estructura del repositorio

```
sql-hr-analytics/
│
├── README.md
├── setup.ipynb              ← Notebook completo: setup + 56 queries con explicaciones
│
├── queries/
│   ├── 01_basico.sql        ← 18 queries: SELECT, DISTINCT, LIKE, IN, BETWEEN,
│   │                           agregación, CASE WHEN, HAVING, COALESCE, NULLIF, CAST
│   ├── 02_intermedio.sql    ← 20 queries: JOINs, subqueries, CTEs,
│   │                           UNION, INTERSECT, EXCEPT, texto y fechas
│   └── 03_avanzado.sql      ← 18 queries: Window functions, LAG/LEAD,
│                               ROWS BETWEEN, PERCENT_RANK, Pareto, cohortes
│
└── schema/
    └── modelo_datos.md      ← Descripción de columnas por tabla
```

---

## 📊 Lo que vas a practicar

| Nivel | Queries | Funciones principales |
|---|---|---|
| 🟢 **Básico** | 18 | `SELECT`, `DISTINCT`, `LIKE`, `IN`, `BETWEEN`, `NOT IN`, `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `ROUND`, `CASE WHEN`, `GROUP BY`, `HAVING`, `COALESCE`, `NULLIF`, `CAST` |
| 🟡 **Intermedio** | 20 | `INNER JOIN`, `LEFT JOIN`, `JOIN triple`, subquery escalar, subquery correlacionada, `IN (subquery)`, `EXISTS`, `CTE` simple/doble/triple, `UNION ALL`, `UNION`, `INTERSECT`, `EXCEPT`, `UPPER`, `LOWER`, `LENGTH`, `TRIM`, `SUBSTR`, `REPLACE`, `strftime` |
| 🔴 **Avanzado** | 18 | `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `NTILE`, `LAG`, `LEAD`, `FIRST_VALUE`, `LAST_VALUE`, `AVG/SUM/COUNT/MIN/MAX OVER`, `ROWS BETWEEN`, `PERCENT_RANK`, `CUME_DIST`, Pareto acumulado, cohortes |

---

## ❓ Preguntas de negocio que responde este proyecto

### 1. ¿Qué departamento tiene la mayor tasa de rotación?

```sql
SELECT
    Department,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS tasa_pct
FROM employee
GROUP BY Department
ORDER BY tasa_pct DESC;
```

| Department | total | rotaron | tasa_pct |
|---|---|---|---|
| Sales | 446 | 92 | 20.6 |
| Human Resources | 63 | 12 | 19.0 |
| Technology | 961 | 133 | 13.8 |

💡 **Insight:** Sales tiene una tasa de rotación 49% más alta que Technology. Los empleados de ventas son el grupo de mayor riesgo y el que más merece intervenciones de retención.

---

### 2. ¿Hacer horas extra duplica la probabilidad de renunciar?

```sql
SELECT
    OverTime,
    COUNT(*) AS total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS rotaron,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS tasa_pct
FROM employee
GROUP BY OverTime
ORDER BY tasa_pct DESC;
```

💡 **Insight:** Los empleados que hacen overtime tienen una tasa de rotación significativamente mayor. Es una de las señales de riesgo más fuertes del dataset.

---

### 3. ¿Cuál es el perfil del empleado que rota vs el que se queda?

```sql
WITH perfil AS (
    SELECT
        Attrition,
        ROUND(AVG(Age), 1)                     AS edad_promedio,
        ROUND(AVG(Salary), 0)                  AS salario_promedio,
        ROUND(AVG(YearsAtCompany), 1)          AS anos_empresa,
        ROUND(AVG(YearsSinceLastPromotion), 1) AS anos_sin_promocion,
        ROUND(AVG(CASE WHEN OverTime = 'Yes' THEN 1.0 ELSE 0 END) * 100, 1) AS pct_overtime
    FROM employee
    GROUP BY Attrition
)
SELECT * FROM perfil;
```

💡 **Insight:** El empleado que rota es más joven, gana menos, lleva menos tiempo en la empresa y tiene una proporción mucho mayor de overtime. Este CTE resume el "retrato robot" de la rotación.

---

### 4. ¿Las capacitaciones reducen la rotación?

```sql
WITH resumen_perf AS (
    SELECT EmployeeID,
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
    ROUND(SUM(CASE WHEN e.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS tasa_rotacion_pct
FROM employee e
INNER JOIN resumen_perf rp ON e.EmployeeID = rp.EmployeeID
GROUP BY nivel_capacitacion
ORDER BY tasa_rotacion_pct DESC;
```

💡 **Insight:** Permite cuantificar si invertir en capacitación tiene retorno en retención — una pregunta clave para cualquier área de RRHH.

---

### 5. ¿Qué JobRoles concentran el 80% de las bajas? (Análisis de Pareto)

```sql
WITH rotacion AS (
    SELECT JobRole,
           SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS bajas
    FROM employee
    GROUP BY JobRole
),
pareto AS (
    SELECT JobRole, bajas,
        ROUND(SUM(bajas) OVER (ORDER BY bajas DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
              * 100.0 / SUM(bajas) OVER (), 1) AS pct_acumulado
    FROM rotacion
)
SELECT JobRole, bajas, pct_acumulado,
    CASE WHEN pct_acumulado <= 80 THEN 'Crítico (80%)' ELSE 'Resto' END AS clasificacion
FROM pareto
ORDER BY bajas DESC;
```

💡 **Insight:** Aplicando la regla 80/20, unos pocos roles concentran la mayoría de las renuncias. Focalizar las iniciativas de retención en esos roles tiene mayor impacto con menos recursos.

---

### 6. ¿La satisfacción laboral de los empleados mejoró o empeoró con el tiempo?

```sql
SELECT
    EmployeeID, ReviewDate, JobSatisfaction,
    LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS sat_anterior,
    JobSatisfaction - LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) AS cambio,
    CASE
        WHEN JobSatisfaction > LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) THEN 'Mejora'
        WHEN JobSatisfaction < LAG(JobSatisfaction) OVER (PARTITION BY EmployeeID ORDER BY ReviewDate) THEN 'Baja'
        ELSE 'Sin cambio'
    END AS tendencia
FROM performance
ORDER BY EmployeeID, ReviewDate
LIMIT 20;
```

💡 **Insight:** `LAG()` permite ver la trayectoria de satisfacción de cada empleado — detectar quiénes llevan varias evaluaciones consecutivas a la baja es más valioso que ver solo la última evaluación.

---

### 7. ¿Qué empleados tienen alto salario pero baja evaluación de su manager?

```sql
WITH deciles AS (
    SELECT EmployeeID, Department, Salary,
           NTILE(10) OVER (PARTITION BY Department ORDER BY Salary DESC) AS decil
    FROM employee
)
SELECT e.FirstName || ' ' || e.LastName AS nombre,
       e.Department, e.Salary, r.RatingLevel
FROM employee e
INNER JOIN deciles d      ON e.EmployeeID = d.EmployeeID
INNER JOIN performance p  ON e.EmployeeID = p.EmployeeID
INNER JOIN rating_level r ON p.ManagerRating = r.RatingID
WHERE d.decil = 1 AND p.ManagerRating <= 2
ORDER BY e.Department, e.Salary DESC;
```

💡 **Insight:** Empleados en el top 10% salarial con rating de manager "Unacceptable" o "Needs Improvement" son un perfil de riesgo costoso — pueden irse o generar conflicto interno.

---

### 8. ¿Cuál es el score de riesgo de rotación de cada empleado?

```sql
-- Score compuesto que combina overtime, años sin promoción,
-- satisfacción laboral, balance vida-trabajo y rating del manager.
-- Mayor puntaje = mayor riesgo de rotación.
```

💡 **Insight:** El score de riesgo combina múltiples señales en un índice accionable. Puedes exportarlo directamente a Power BI o Tableau para construir un dashboard de alerta temprana de rotación.

---

### 9. ¿Las cohortes de contratación más antiguas tienen más rotación?

```sql
SELECT strftime('%Y', HireDate) AS anio,
       COUNT(*) AS contratados,
       ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS tasa_pct,
       SUM(COUNT(*)) OVER (ORDER BY strftime('%Y', HireDate)
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS headcount_acumulado
FROM employee
GROUP BY anio
ORDER BY anio;
```

💡 **Insight:** El análisis de cohortes revela si hay patrones temporales en la rotación — ¿se van más los que entraron en ciertos años? ¿Las contrataciones recientes son más estables?

---

### 10. ¿Qué porcentaje de la masa salarial concentra cada departamento?

```sql
WITH masa AS (
    SELECT Department, SUM(Salary) AS masa_salarial
    FROM employee GROUP BY Department
)
SELECT Department, masa_salarial,
    ROUND(masa_salarial * 100.0 / SUM(masa_salarial) OVER (), 1) AS pct_masa,
    ROUND(SUM(masa_salarial) OVER (ORDER BY masa_salarial DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          * 100.0 / SUM(masa_salarial) OVER (), 1) AS pct_acumulado
FROM masa
ORDER BY masa_salarial DESC;
```

💡 **Insight:** Combina participación individual y acumulada para ver cómo se distribuye el costo salarial. Patrón reutilizable para cualquier análisis de concentración (ventas, clientes, productos).

---

## 🚀 Cómo usar este repositorio

**Opción A — Notebook completo (recomendado):**
1. Abre el notebook con el badge **Open in Colab** al inicio de este README
2. Sube tu `kaggle.json` cuando el notebook lo solicite
3. Ejecuta las celdas en orden — cada query tiene su explicación integrada

**Opción B — Archivos SQL independientes:**
1. Clona el repositorio
2. Abre cualquier archivo `.sql` de la carpeta `queries/`
3. Ejecuta las queries en tu motor preferido (SQLite, PostgreSQL, SQL Server)

> ⚠️ Algunas funciones como `strftime()` son específicas de SQLite. En otros motores usa `YEAR()`, `DATE_PART()` o `FORMAT()` según corresponda.

---

## 👤 Autor

**rafa37** — Ingeniero Industrial | Data Analyst

[![Kaggle](https://img.shields.io/badge/Kaggle-rafa37-20BEFF?style=flat-square&logo=kaggle&logoColor=white)](https://www.kaggle.com/rafa37)

Si este repositorio te fue útil, déjale una ⭐ — ayuda a que más personas lo encuentren.
