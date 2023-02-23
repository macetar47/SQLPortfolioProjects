/* 
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY  3,4

select *
FROM CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY  3,4


--Select data that we are going to use

SELECT  location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1, 2

--Looking at Total cases vs. Total Deaths
--To look at chances of dying if you get covid in a specific country

SELECT  location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS MortalityRate
FROM CovidDeaths
WHERE location LIKE '%states' 
ORDER BY 1, 2

--Total Cases vs Population
--To see percentage of population infected with covid in each country

SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectedPercentage
FROM CovidDeaths
ORDER BY 1,2


--Countries with Highest Infection rate relative to Population
SELECT continent, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY PercentPopulationInfected DESC

--Country with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Creating View--

CREATE VIEW DeathPerCountry AS 
SELECT Location, MAX(Cast(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
Group By location

SELECT Location, TotalDeathCount AS TotalDeaths
FROM DeathPerCountry
ORDER BY TotalDeathCount DESC

--Deaths Per Continent with Drill Down Effect for Future Visualization

SELECT Continent, SUM(MaxTotalDeathCount) AS TotalDeaths
FROM (SELECT Continent, MAX(Cast(Total_deaths AS INT)) AS MaxTotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY Continent, Location) AS MaxTotalDeathCounts
GROUP BY Continent
ORDER BY TotalDeaths DESC

--Creating View--

CREATE VIEW TotalDeathsPerContinent AS 
SELECT Continent, SUM(MaxTotalDeathCount) AS TotalDeaths
FROM (SELECT Continent, MAX(Cast(Total_deaths AS INT)) AS MaxTotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY Continent, Location) AS MaxTotalDeathCounts
GROUP BY Continent

SELECT Continent, TotalDeaths
FROM TotalDeathsPerContinent
ORDER BY TotalDeaths DESC


--GLOBAL Numbers--

--Total Deaths, Total Cases, and DeathPercentage By Date
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE Continent is not null
GROUP BY date
ORDER BY 1,2

--Total Deaths, Cases, and DeathPercentage of World
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE Continent is not null
ORDER BY 1,2



--Total Population Vs Vaccination W/ Rolling Count of Newly Vaccinated People

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint, vac.New_vaccinations)) OVER (Partition By dea.location Order By dea.Location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null


--Create CTE to Perform Calculation on "Partition By" in previous query
WITH PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint, vac.New_vaccinations)) OVER (Partition By dea.location Order By dea.Location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths as dea
Join CovidVaccinations as Vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM PopVsVac



--Temp Table For Percent Population Vaccinated--

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_vaccination numeric, RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint, vac.New_vaccinations)) OVER (Partition By dea.location Order By dea.Location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths as dea
Join CovidVaccinations as Vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null


SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated



--Creating view for Percent Population Vaccinated--

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint, vac.New_vaccinations)) OVER (Partition By dea.location Order By dea.Location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths as dea
Join CovidVaccinations as Vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM PercentPopulationVaccinated


--Temp Table with Drill Down Effect for Total Deaths per Continent--

DROP TABLE IF EXISTS #TotalDeathsPerContinent
CREATE TABLE #TotalDeathsPerContinent
(Continent nvarchar(255), Location nvarchar(255), TotalDeathCount numeric)

INSERT INTO #TotalDeathsPerContinent
SELECT Continent, Location, MAX(Cast(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
Group By Continent, Location
Order By TotalDeathCount DESC


SELECT Continent, SUM(Cast(TotalDeathCount AS INT)) AS TotalDeaths
FROM #TotalDeathsPerContinent
Group BY Continent


--Creating View--
CREATE VIEW TotalDeathsPerCountry AS 
SELECT Continent, Location, MAX(Cast(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
Group By Continent, Location



SELECT Continent, SUM(Cast(TotalDeathCount AS INT)) AS TotalDeaths
FROM TotalDeathsPerCountry

SELECT Location, TotalDeathCount
FROM TotalDeathsPerCountry



