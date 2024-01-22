select * from 
CovidProject..Covid_death$ order by 3,4

--select * from 
--CovidProject..Covid_vaccination$ order by 3,4

select location, date, total_cases,new_cases, total_deaths, population
from CovidProject..Covid_death$
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths,
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
FROM CovidProject..Covid_death$
WHERE location LIKE '%india%'
ORDER BY 1, 2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidProject..Covid_death$
Where location like '%states%'
order by 1,2

-- countries with highest infection rate
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..Covid_death$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--Countries with highesht death count

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidProject..Covid_death$
--Where location like '%states%'
where continent is not null
Group by Location, Population
order by TotalDeathCount desc

--by continent
--showing continent with highest death count per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidProject..Covid_death$
--Where location like '%india%'
where continent is not null
Group by continent
order by TotalDeathCount desc

--Global Members
SELECT date, Sum(new_cases)as total_cases, sum(convert(int,new_deaths)) as total_death, sum(convert(int,new_deaths))/Sum(new_cases)*100 as DeathPercentage
--(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
FROM CovidProject..Covid_death$
WHERE continent is not null
group by date
ORDER BY 1, 2;


--joining tables
select * from 
CovidProject..Covid_death$ as d 
join CovidProject..Covid_vaccination$ as v
on d.location=v.location and d.date=v.date

--Looking at total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..Covid_death$ dea
Join CovidProject..Covid_vaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

--Using CTE to perform Calculation on Partition By in previous query

with popsvac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
as(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..Covid_death$ dea
Join CovidProject..Covid_vaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
) Select *, (RollingPeopleVaccinated/Population)*100
from popsvac

--temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(numeric(18, 2), vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    CovidProject..Covid_death$ dea
JOIN
    CovidProject..Covid_vaccination$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

-- Drop the existing view if it exists
IF OBJECT_ID('dbo.PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW dbo.PercentPopulationVaccinated;

-- Create the new view
CREATE VIEW dbo.PercentPopulationVaccinated
AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM
    CovidProject..Covid_death$ dea
JOIN
    CovidProject..Covid_vaccination$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;



select * from dbo.PercentPopulationVaccinated


