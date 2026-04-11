# Modelo de datos — HR Analytics

## Diagrama de relaciones

employee (1) ────────────── (N) performance
│
│ Education ──► education_level (EducationLevelID)
│
│              performance.EnvironmentSatisfaction ──► satisfied_level
│              performance.JobSatisfaction          ──► satisfied_level
│              performance.RelationshipSatisfaction ──► satisfied_level
│              performance.WorkLifeBalance          ──► satisfied_level
│              performance.ManagerRating            ──► rating_level
│              performance.SelfRating               ──► rating_level

## Tabla: employee

| Columna | Tipo | Descripción |
|---|---|---|
| EmployeeID | TEXT | ID único del empleado |
| FirstName | TEXT | Nombre |
| LastName | TEXT | Apellido |
| Gender | TEXT | Male / Female |
| Age | INT | Edad en años |
| BusinessTravel | TEXT | No Travel / Some Travel / Frequent Traveller |
| Department | TEXT | Sales / Technology / Human Resources |
| DistanceFromHome (KM) | INT | Distancia al trabajo en km |
| State | TEXT | Estado (USA) |
| Ethnicity | TEXT | Etnia |
| Education | INT | FK → education_level.EducationLevelID (1-5) |
| EducationField | TEXT | Campo de estudio |
| JobRole | TEXT | 13 roles posibles |
| MaritalStatus | TEXT | Single / Married / Divorced |
| Salary | INT | Salario anual |
| StockOptionLevel | INT | Nivel de opciones sobre acciones (0-3) |
| OverTime | TEXT | Yes / No |
| HireDate | DATE | Fecha de contratación (2012-2022) |
| Attrition | TEXT | Yes = rotó / No = activo |
| YearsAtCompany | INT | Años en la empresa |
| YearsInMostRecentRole | INT | Años en el rol actual |
| YearsSinceLastPromotion | INT | Años desde la última promoción |
| YearsWithCurrManager | INT | Años con el manager actual |

## Tabla: performance

| Columna | Tipo | Descripción |
|---|---|---|
| PerformanceID | TEXT | ID único de la evaluación |
| EmployeeID | TEXT | FK → employee.EmployeeID |
| ReviewDate | DATE | Fecha de la evaluación |
| EnvironmentSatisfaction | INT | FK → satisfied_level (1-5) |
| JobSatisfaction | INT | FK → satisfied_level (1-5) |
| RelationshipSatisfaction | INT | FK → satisfied_level (1-5) |
| TrainingOpportunitiesWithinYear | INT | Capacitaciones disponibles en el año |
| TrainingOpportunitiesTaken | INT | Capacitaciones tomadas |
| WorkLifeBalance | INT | FK → satisfied_level (1-5) |
| SelfRating | INT | FK → rating_level (1-5) |
| ManagerRating | INT | FK → rating_level (1-5) |

## Tablas de dimensión

### education_level
| EducationLevelID | EducationLevel |
|---|---|
| 1 | No Formal Qualifications |
| 2 | High School |
| 3 | Bachelors |
| 4 | Masters |
| 5 | Doctorate |

### rating_level
| RatingID | RatingLevel |
|---|---|
| 1 | Unacceptable |
| 2 | Needs Improvement |
| 3 | Meets Expectation |
| 4 | Exceeds Expectation |
| 5 | Above and Beyond |

### satisfied_level
| SatisfactionID | SatisfactionLevel |
|---|---|
| 1 | Very Dissatisfied |
| 2 | Dissatisfied |
| 3 | Neutral |
| 4 | Satisfied |
| 5 | Very Satisfied |
