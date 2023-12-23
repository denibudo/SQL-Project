SELECT *
FROM [Portfolio Project].dbo.CovidDeaths
ORDER BY date

--Select Data I am going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project].dbo.CovidDeaths 
ORDER BY 1,2

--Total cases Vs Total Deaths
--Likelihood of dying of you contracted Covid19 in North Macedonia
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM [Portfolio Project].dbo.CovidDeaths 
WHERE location LIKE('%donia')
ORDER BY 1,2


--Deleting columns with NULL VALUES
DELETE FROM [Portfolio Project].dbo.CovidDeaths 
WHERE population IS NULL AND total_cases IS NULL 

--Looking at Total cases Vs Population, which show what percentage of population got Covid19. I am analyzing here my country North Macedonia.

SELECT location, date,population, total_cases, ROUND((total_cases/population)*100,4) AS percentage_of_population_infected
FROM [Portfolio Project].dbo.CovidDeaths 
WHERE location LIKE('%donia')
ORDER BY 1,2

--Looking at countries with highest infection rate compared to the population

SELECT location,population, MAX(total_cases) AS highest_infection_count, ROUND(MAX((total_cases/population))*100,4) AS percentage_of_population_infected
FROM [Portfolio Project].dbo.CovidDeaths 
GROUP BY location, population
ORDER BY percentage_of_population_infected DESC


--Country with highest Deatch Count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count    --With CAST, I am converting data type from "nvarchar(255)" to "int".
FROM [Portfolio Project].dbo.CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


--Let's break things down by continents

--Showing the continents with highest Death Count

SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count   
FROM [Portfolio Project]. dbo.CovidDeaths 
WHERE continent IS NULL AND location NOT IN('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC


--GLOBAL NUMBERS by Date

SELECT date, SUM(new_cases) AS total_cases,SUM(CAST(new_deaths AS int)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100,2) as death_percentage
FROM [Portfolio Project].dbo.CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--GLOBAL NUMBERS Overall

SELECT SUM(new_cases) AS total_cases,SUM(CAST(new_deaths AS int)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100,2) as death_percentage
FROM [Portfolio Project].dbo.CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 1,2


--Looking at Total Population Vs Vaccination
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS sum_of_people_vaccinated,
FROM [Portfolio Project].dbo.CovidDeaths AS dea
INNER JOIN [Portfolio Project].dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3



--Use of CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, sum_of_people_vaccinated)
AS(
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS sum_of_people_vaccinated
FROM [Portfolio Project].dbo.CovidDeaths AS dea
INNER JOIN [Portfolio Project].dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, ROUND(sum_of_people_vaccinated/population*100,2)AS vaccinated_population_percentage
FROM pop_vs_vac
WHERE new_vaccinations IS NOT NULL 



--Use of TEMP TABLE

DROP TABLE IF EXISTS #population_vaccinated
CREATE TABLE #population_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Sum_of_people_vaccinated numeric
)

INSERT INTO #population_vaccinated
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS sum_of_people_vaccinated
FROM [Portfolio Project].dbo.CovidDeaths AS dea
INNER JOIN [Portfolio Project].dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date

SELECT *, ROUND(sum_of_people_vaccinated/population*100,2)AS vaccinated_population_percentage
FROM #population_vaccinated
ORDER BY 2



-- Creating VIEW to store data for Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS sum_of_people_vaccinated
FROM [Portfolio Project].dbo.CovidDeaths AS dea
INNER JOIN [Portfolio Project].dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM dbo.PercentPopulationVaccinated
