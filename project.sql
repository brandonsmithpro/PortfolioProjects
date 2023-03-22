/*
Covid 19 Data Exploration

Skills Implemented: Joins, CTE's, Windows Functions, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types, Filtering Data

*/

SELECT *
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--Select data that we will start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


--Looking at total cases vs total deaths
--Shows likelihood of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


--Likelihood of dying from contracying Covid in the USA

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject.CovidDeaths
WHERE location = 'United States'
ORDER BY location, date


--Shows what percentage of population infected with Covid

SELECT location, date, total_cases, population, CAST((total_cases/population) as decimal)*100 AS infected_percentage
FROM PortfolioProject.CovidDeaths
WHERE location = 'United States'
ORDER BY location, date


--Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS infected_percentage
FROM PortfolioProject.CovidDeaths
GROUP BY location, population
ORDER BY infected_percentage DESC


--Countries with highest death count per population 

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.CovidDeaths
WHERE NOT location IN ('World','Europe','Asia','North America','South America','European Union','High income', 'Upper middle income', 'Lower middle income','Low income','Africa','Oceania')
GROUP BY location
ORDER BY total_death_count DESC


--BREAKING THINGS DOWN BY CONTINENT

--Showing the continents with the highest death count per population

SELECT location, MAX(total_deaths) AS total_death_count
FROM PortfolioProject.CovidDeaths
WHERE continent IS NULL 
  AND location <> 'World'
  AND NOT location LIKE '%income'
GROUP BY location
ORDER BY total_death_count DESC


-- Global Numbers, new cases and deaths each day - worldwide

SELECT  date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE (SUM(new_deaths))/(SUM(new_cases))*100 
    END AS death_percentage
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--Global Totals

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE (SUM(new_deaths))/(SUM(new_cases))*100 
    END AS death_percentage
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Drilling down by continent and location

SELECT continent, location, SUM(total_deaths) AS total_deaths
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY continent, location


--Total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated,
  --(rolling_people_vaccinated/population)*100
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER by 1,2,3  


--Using CTE to perform calculation on partition by in previous query

WITH PopvsVac 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac


--Using Temp Table to perform calculation on partition by in previous query

DROP TABLE IF EXISTS
CREATE TEMP TABLE percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
)

SELECT *, (rolling_people_vaccinated/population)*100
FROM percent_population_vaccinated


--Creating VIEW to store for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
