--Showing all column From CovidDeath looking at all data in the table
SELECT *
FROM CovidDeaths

--Showing all column From CovidDeath where continent is not null and order the column by column 3 (location) and 4 (date). 
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Showing selected column (location, date, total_cases, new_cases, total_deaths, and population) from CovidDeath table where continent is not null and order the column by column 1 (location) and 2 (date). 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Showing Total Cases vs Total Deaths (CovidDeath%) - Shows likelihood of dying if you contract covid in Nigeria
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM CovidDeaths
WHERE location = 'Nigeria' AND
continent IS NOT NULL
ORDER BY 1, 2

-- Showing the Total cases vs Population (%PopulationInfected) - Shows what percentage of population got Covid in Nigeria
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location = 'Nigeria' AND 
continent IS NOT NULL
ORDER BY 1, 2

-- Showing countries with Highest Infection rate compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC

-- Showing countries with Highest death count per Population
SELECT location, population, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

--Showing continent with the highest death count
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- A way around the query above to get accurate figures 
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Showing Global numbers per date/day
SELECT date, SUM(new_cases) as TotalDailyNewCases, SUM(cast(new_deaths as int)) as TotalDailyDeathCount, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Deathpercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--Showing Global Total
SELECT SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeathCount, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Deathpercentage
FROM CovidDeaths
WHERE continent IS NOT NULL

-- Showing Total Population vs Vaccination
SELECT death.continent, death.location, death.date, death.population, vaccinated.new_vaccinations, 
	SUM(cast(vaccinated.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated -- This rolls the current number with the previous number 
	--SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location) alternative to 'cast'
FROM CovidDeaths death
JOIN CovidVaccinations vaccinated
	 ON death.location = vaccinated.location
	 AND death.date = vaccinated.date
WHERE death.continent IS NOT NULL --To remove the null values
	AND vaccinated.new_vaccinations IS NOT NULL --To remove the null values
ORDER BY 2,3

--Using CTE to get the percentage of RollingPeopleVaccinated
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated -- This rolls the number with the previous number 
	--SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location)
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS Percentage
FROM PopVsVac

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- Add this so when you run it multiple time it doesn't give an error.
CREATE TABLE #PercentPopulationVaccinated  -- Creating Temp Table 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated -- This rolls the number with the previous number 
	--SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location) alternative to 'cast'
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS Percentage
FROM #PercentPopulationVaccinated
ORDER BY 1,2


-- CREATING View to store data for later visulizations 
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated -- This rolls the number with the previous number 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL