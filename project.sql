--looking at total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM `PortfolioProject.CovidDeaths`
ORDER BY location, date

--Lets focus in on the USA
--shows the likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM `PortfolioProject.CovidDeaths`
WHERE location = 'United States'
ORDER BY location, date

--Looking at the total cases vs the population
--shows what percentage of population got Covid 
SELECT location, date, total_cases, population, CAST((total_cases/population) as decimal)*100 AS infected_percentage
FROM `PortfolioProject.CovidDeaths`
WHERE location = 'United States'
ORDER BY location, date

--looking at countries with highest infection rate compared to population 
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS infected_percentage
FROM `PortfolioProject.CovidDeaths`
GROUP BY location, population
ORDER BY infected_percentage DESC


--showing countries with highest death count per population 
SELECT location, MAX(total_deaths) AS total_death_count
FROM `PortfolioProject.CovidDeaths`
WHERE NOT location IN ('World','Europe','Asia','North America','South America','European Union','High income', 'Upper middle income', 'Lower middle income','Low income','Africa','Oceania')
GROUP BY location
ORDER BY total_death_count DESC

SELECT location, MAX(total_deaths) AS total_death_count
FROM `PortfolioProject.CovidDeaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--LETS BREAK THINGS DOWN BY CONTINENT
--Showing the continents with the highest death counts
SELECT location, MAX(total_deaths) AS total_death_count
FROM `PortfolioProject.CovidDeaths`
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
FROM `PortfolioProject.CovidDeaths`
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Same thing, but overall total
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE (SUM(new_deaths))/(SUM(new_cases))*100 
    END AS death_percentage
FROM `PortfolioProject.CovidDeaths`
WHERE continent IS NOT NULL
ORDER BY 1,2

--Drilling down by continent and location
SELECT continent, location, SUM(total_deaths) AS total_deaths
FROM `PortfolioProject.CovidDeaths`
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY continent, location


--Joining the Vaccine table
--looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated,
  --(rolling_people_vaccinated/population)*100
FROM `PortfolioProject.CovidDeaths` dea
JOIN `PortfolioProject.CovidVaccinations` vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER by 1,2,3  

--USE CTE

WITH PopvsVac 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM `PortfolioProject.CovidDeaths` dea
JOIN `PortfolioProject.CovidVaccinations` vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac

--Temp table
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
FROM `PortfolioProject.CovidDeaths` dea
JOIN `PortfolioProject.CovidVaccinations` vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM percent_population_vaccinated


--CREATE VIEW FOR LATER VISUALIZATION -This is not working with BIGQUERY
CREATE VIEW percent_population_vaccinated AS
WITH percent_population_vaccinated 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM `PortfolioProject.CovidDeaths` dea
JOIN `PortfolioProject.CovidVaccinations` vac
  ON dea.location=vac.location
  AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM percent_population_vaccinated