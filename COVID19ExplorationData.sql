/*
Covid 19 Data Exploration

Data from 1/1/20 - 8/2/23

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Select the data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID-19 in your country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS numeric)/CAST(total_cases AS numeric))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL 
	AND location = 'United States'
ORDER BY location, date



-- Total Cases vs Population
-- Shows percentage of the population that were infected with COVID-19

SELECT location, date, population, total_cases, (CAST(total_cases AS numeric)/population)*100 AS PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL 
	AND location = 'United States'
ORDER BY location, date



-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(CAST(total_cases AS numeric)) AS HighestInfectionCount, MAX((CAST(total_cases AS numeric)/population))*100 AS PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC



-- Countries with Highest Death Count per Population

SELECT location, population, MAX(CAST(total_deaths AS numeric)) AS TotalDeathCount, (MAX(CAST(total_deaths AS numeric))/population)*100 AS TotalDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the Highest Death Count per Population

SELECT location, population, MAX(CAST(total_deaths AS numeric)) AS TotalDeathCount, (MAX(CAST(total_deaths AS numeric))/population)*100 AS TotalDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL 
	AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY TotalDeathCount DESC




-- GLOBAL NUMBERS

-- COVID-19 Total Death Percentage by Date

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/Nullif(Sum(new_cases),0))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- COVID-19 Total Death Percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/Nullif(Sum(new_cases),0))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(NUMERIC, vac.new_vaccinations))
OVER (PARTITION BY dea.location 
	  ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date



-- Using CTE to Perform Calculation on Partition By in Previous Query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(NUMERIC, vac.new_vaccinations))
OVER (PARTITION BY dea.location 
	  ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPeopleVaccinatedPercentage
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(NUMERIC, vac.new_vaccinations))
OVER (PARTITION BY dea.location 
	  ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPeopleVaccinatedPercentage
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(NUMERIC, vac.new_vaccinations))
OVER (PARTITION BY dea.location 
	  ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL