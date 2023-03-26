/*
Covid 19 Data Exploration

Skills Implemented: Joins, CTE's, Windows Functions, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types, Filtering Data

This SQL syntax is formated for postgreSQL
*/

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--Select data that we will start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


--Looking at total cases vs total deaths
--Shows likelihood of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as float)/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


--Likelihood of dying from contracting Covid in the USA

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as float)/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY location, date


--Shows what percentage of population infected with Covid in USA

SELECT location, date, total_cases, population, (CAST(total_cases as float)/population)*100 AS infected_percentage
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY location, date


--Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((CAST(total_cases as float)/population))*100 AS infected_percentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY infected_percentage DESC


--Countries with highest death count per population 

SELECT location, MAX(total_deaths) AS total_death_count
FROM CovidDeaths
WHERE NOT location IN ('World','Europe','Asia','North America','South America','European Union','High income', 'Upper middle income', 'Lower middle income','Low income','Africa','Oceania')
	AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


--BREAKING THINGS DOWN BY CONTINENT

--Showing the continents with the highest death count per population

SELECT location, MAX(total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent IS NULL 
  AND location <> 'World'
  AND NOT location LIKE '%income'
GROUP BY location
ORDER BY total_death_count DESC


-- Global Numbers, new cases and deaths each day - worldwide

SELECT  date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE (SUM(CAST(new_deaths as float)))/(SUM(new_cases))*100 
    END AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--Global Totals

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE (SUM(CAST(new_deaths as float)))/(SUM(new_cases))*100 
    END AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Drilling down by continent and location

SELECT continent, location, SUM(total_deaths) AS total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY continent, location


--Total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed AS new_people_vaccinated,
  SUM(vac.new_people_vaccinated_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
  --(rolling_people_vaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER by 1,2,3  



--Same calculation as above, with respect to United States only
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed AS new_people_vaccinated,
  SUM(vac.new_people_vaccinated_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
  --(rolling_people_vaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
	AND dea.location = 'United States'
ORDER by 1,2,3

--Using CTE to perform calculation on partition by in previous query

WITH PopvsVac 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
  SUM(vac.new_people_vaccinated_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (CAST(rolling_people_vaccinated as float)/population)*100 AS percentage_population_vaccinated
FROM PopvsVac


--Using Temp Table to perform calculation on partition by in previous query

DROP TABLE IF EXISTS
CREATE TEMP TABLE percent_population_vaccinated
(
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_people_vaccinated numeric,
rolling_people_vaccinated numeric
)

INSERT INTO percent_population_vaccinated
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
  SUM(vac.new_people_vaccinated_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
)

SELECT *, (rolling_people_vaccinated/population)*100 AS percentage_popluation_vaccinated
FROM percent_population_vaccinated

--Using our temp table to show percentage of US citizens vaccinated
SELECT *, (rolling_people_vaccinated/population)*100 AS percentage_popluation_vaccinated
FROM percent_population_vaccinated
WHERE location = 'United States'

--Creating VIEW to store for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
  SUM(vac.new_people_vaccinated_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
