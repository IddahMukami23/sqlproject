SELECT * 
FROM CovidDeaths$;



 --FROM COVIDDEATHS$

 SELECT location,date,total_cases,new_cases,total_deaths,new_deaths, population
 FROM CovidDeaths$
 ORDER BY 1,2;

 -- handling the missing values in Coviddeaths
 UPDATE CovidDeaths$
 SET total_cases = 0
 WHERE total_cases IS NULL;

 UPDATE CovidDeaths$
 SET total_deaths = 0
 WHERE total_deaths IS NULL;

 -- Formatting dates uniformly
 UPDATE CovidDeaths$
 SET date = CONVERT(DATE, Date, 23);

-- looking at new_cases vs new_deaths
 SELECT location,date,new_cases,new_deaths,
 CASE WHEN new_cases<>0
 THEN(new_deaths/new_cases)*100 
 ELSE NULL
 END AS NewDeathPercentage
 FROM CovidDeaths$
 WHERE location = 'Australia'
 ORDER BY 1,2;

 --looking at the new_cases vs population

SELECT location, date,new_cases,population,
(new_cases/population)*100 AS InfectedPopulationPercentage
FROM CovidDeaths$
WHERE location = 'Australia'
ORDER BY 1,2;

--looking at locations with the highest infection rate compared to population
SELECT location,population, MAX(new_cases) AS HighestNewInfectionCount,(MAX(new_cases)/population)*100 AS MaxInfectedPopulationpercentage
 FROM CovidDeaths$
 GROUP BY location,population
 ORDER BY MaxInfectedPopulationpercentage DESC;

 -- showing locations with the highest current deaths per population
 SELECT location, MAX(new_deaths) AS LatestDeathCount
 FROM CovidDeaths$
 WHERE continent IS NOT NULL
 GROUP BY location
 ORDER BY LatestDeathCount DESC;

 -- Global numbers
 SELECT continent, MAX(new_deaths) AS LatestDeathCount
 FROM CovidDeaths$
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY LatestDeathCount DESC;

 SELECT date,SUM(new_cases) AS TotalNewCases,SUM(CAST(new_deaths AS int)) AS TotalNewDeaths,
 CASE
 WHEN SUM(new_cases)<>0
 THEN SUM(CAST(new_deaths AS int))/SUM(new_cases)*100
 ELSE NULL
 END AS GlobalDeathPercentage
 FROM CovidDeaths$
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY date DESC;


 SELECT  SUM(new_cases) AS TotalNewCases,SUM(CAST(new_deaths AS int)) AS TotalNewDeaths,
 CASE
 WHEN SUM(new_cases)<>0
 THEN SUM(CAST(new_deaths AS int))/SUM(new_cases)*100
 ELSE NULL
 END AS GlobalDeathPercentage
 FROM CovidDeaths$
 WHERE continent IS NOT NULL
 ORDER BY 1,2;


 SELECT*
FROM CovidVaccines$;

SELECT*
FROM CovidDeaths$ CDs
JOIN CovidVaccines$ CVs
ON CDs.location = CVs.location
AND CDs.date = CVs.date;

-- total population vs vaccinations
SELECT CDs.continent,CDs.location,CDs.date,CDs.population,CVs.new_vaccinations
FROM CovidDeaths$ CDs
JOIN CovidVaccines$ CVs
ON CDs.location = CVs.location
AND CDs.date = CVs.date
WHERE CDs.continent IS NOT NULL
ORDER BY 1,2,3;

SELECT CDs.continent,CDs.location,CDs.date,CDs.population,CVs.new_vaccinations,
SUM(CAST(CVs.new_vaccinations AS int)) OVER (PARTITION BY CDs.location ORDER BY CDs.location, CDs.date)
AS RollingPeopleVaccinated
FROM CovidDeaths$ CDs
JOIN CovidVaccines$ CVs
ON CDs.location = CVs.location
AND CDs.date = CVs.date
WHERE CDs.continent IS NOT NULL
ORDER BY 1,2,3;

--cte
WITH PopulationvsVaccination(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
AS(
SELECT CDs.continent,CDs.location,CDs.date,CDs.population,CVs.new_vaccinations,
SUM(CAST(CVs.new_vaccinations AS int)) OVER (PARTITION BY CDs.location ORDER BY CDs.location, CDs.date)
AS RollingPeopleVaccinated
FROM CovidDeaths$ CDs
JOIN CovidVaccines$ CVs
ON CDs.location = CVs.location
AND CDs.date = CVs.date
WHERE CDs.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT*,(RollingPeopleVaccinated/population)*100
FROM PopulationvsVaccination;


-- temp table

DROP TABLE IF EXISTS  #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT CDs.continent,CDs.location,CDs.date,CDs.population,CVs.new_vaccinations,
SUM(CAST(CVs.new_vaccinations AS int)) OVER (PARTITION BY CDs.location ORDER BY CDs.location, CDs.date)
AS RollingPeopleVaccinated
FROM CovidDeaths$ CDs
JOIN CovidVaccines$ CVs
ON CDs.location = CVs.location
AND CDs.date = CVs.date
--WHERE CDs.continent IS NOT NULL
--ORDER BY 2,3
SELECT*,(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;


---CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT CDs.continent,CDs.location,CDs.date,CDs.population,CVs.new_vaccinations,
SUM(CAST(CVs.new_vaccinations AS int)) OVER (PARTITION BY CDs.location ORDER BY CDs.location, CDs.date)
AS RollingPeopleVaccinated
FROM CovidDeaths$ CDs
JOIN CovidVaccines$ CVs
ON CDs.location = CVs.location
AND CDs.date = CVs.date;
--WHERE CDs.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated;
