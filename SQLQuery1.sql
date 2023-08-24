-- Quick preview of some columns in the database(CovidDeath table)

 SELECT Location,date,
	total_cases,new_cases,
		total_deaths,population
 FROM CovidDeaths$
 WHERE continent is not null
 ORDER BY 1,2
 

--Continents by infection count

SELECT Location,
	SUM(CAST(total_cases AS FLOAT)) AS TotalCases
 FROM CovidDeaths$
 where continent is null
 GROUP BY Location
 ORDER BY TotalCases Desc

--Countries by infection count

SELECT Location,
	SUM(CAST(total_cases AS FLOAT)) AS TotalCases
 FROM CovidDeaths$
 where continent is not null
 GROUP BY Location
 ORDER BY TotalCases Desc

 
--Location(countries) by infection percentage

 SELECT Location,population,
	MAX(CAST(total_cases AS FLOAT)) AS Highestinfection,
		MAX(CAST(total_cases AS FLOAT)/population)*100 AS PercentInfected
  FROM CovidDeaths$
  WHERE continent is not null
  GROUP BY Location,population
  ORDER BY PercentInfected desc
  
--Location(continent) by infection percentage

  SELECT Location,population,
	MAX(CAST(total_cases AS FLOAT)) AS Highestinfection,
		MAX(CAST(total_cases AS FLOAT)/population)*100 AS PercentInfected
  FROM CovidDeaths$
  WHERE continent is null
  GROUP BY Location,population
  ORDER BY PercentInfected desc

 -- Lets see how the Covid cases in poland changed over the days

  SELECT TOP 100 Location,date,
	population,total_cases,
		(CAST(total_cases AS FLOAT)/population)*100 AS Percentinfected,
			ROUND(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100,2) AS PercentDeath
  FROM CovidDeaths$
  WHERE Location like '%poland' and continent is not null
  ORDER BY Percentinfected Desc

-- Countries by death count

SELECT location,MAX(CAST(total_deaths AS FLOAT)) AS Total_countDeath
FROM CovidDeaths$
WHERE continent is not null
GROUP BY Location
ORDER BY Total_countDeath Desc

-- Continents by death count

SELECT location, SUM(CAST(total_deaths AS FLOAT)) AS Total_contDeath
FROM CovidDeaths$
WHERE continent is null
GROUP BY Location
ORDER BY Total_contDeath Desc


-- Location(countries) by percentage death

 SELECT Location,
	ROUND(MAX(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100,2) AS PercentDeath
 FROM CovidDeaths$
 WHERE continent is not null
 GROUP BY Location
 ORDER BY PercentDeath Desc


-- Location(continents) by percentage count

 SELECT Location,
	ROUND(MAX(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100,2) AS PercentDeath
 FROM CovidDeaths$
 WHERE continent is null
 GROUP BY Location
 ORDER BY PercentDeath Desc

-- Percent infected and Percent death
SELECT Location,
	ROUND(SUM(CAST(total_cases AS INT)/population)*100,2) AS Percentinfected,
		ROUND(SUM(CAST(total_deaths AS FLOAT))/SUM(CAST(total_cases AS FLOAT))*100,2) AS PercentDeath
  FROM CovidDeaths$
  WHERE continent is not null
  GROUP BY location
  ORDER BY Percentinfected Desc

SELECT Location,
	ROUND(SUM(CAST(total_cases AS INT)/population)*100,2) AS Percentinfected,
		ROUND(SUM(CAST(total_deaths AS FLOAT))/SUM(CAST(total_cases AS FLOAT))*100,2) AS PercentDeath
  FROM CovidDeaths$
  WHERE continent is null
  GROUP BY location
  ORDER BY Percentinfected Desc

-- Join the CovidDeath and Covidvaccination table

SELECT CDT.location,
	SUM(CAST(CVT.new_vaccinations as float))as New_V
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
WHERE CDT.continent is not null
GROUP BY CDT.location
ORDER BY New_V DESC

SELECT TOP 20 CDT.location,
	SUM(CAST(CVT.new_vaccinations AS FLOAT))AS New_V
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
AND CVT.date=CDT.date
WHERE CDT.continent is not null
GROUP BY CDT.location
ORDER BY New_V DESC

--The number of people vaccinated(Rollover) by location

SELECT CDT.location,CDT.date,
	CDT.population,CVT.new_vaccinations,
		SUM(CONVERT(FLOAT,CVT.new_vaccinations)) OVER(Partition BY CDT.location ORDER BY CDT.location,CDT.date) 
			AS Vaccinatedrollover
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
AND CVT.date=CDT.date 
WHERE CDT.continent is not null
ORDER BY Vaccinatedrollover DESC

SELECT CDT.location,CDT.date,
	CDT.population,CVT.new_vaccinations,
		SUM(CONVERT(FLOAT,CVT.new_vaccinations)) OVER(Partition BY CDT.location ORDER BY CDT.location,CDT.date) 
			AS Vaccinatedrollover
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
AND CVT.date=CDT.date 
WHERE CDT.continent is null
ORDER BY Vaccinatedrollover DESC


	  
-- A common table expression showing locations by percentage vaccinated

WITH vaccinatedPop(continent,location,date,population,new_vaccinations,Vaccinatedrollover)
AS
(
SELECT CDT.continent,CDT.location,
	CDT.date,CDT.population,CVT.new_vaccinations,
		SUM(CONVERT(FLOAT,CVT.new_vaccinations)) 
			OVER(Partition BY CDT.location ORDER BY CDT.location,CDT.date) 
				AS Vaccinatedrollover
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
AND CVT.date=CDT.date	
WHERE CDT.continent is not null
)
SELECT *,ROUND((Vaccinatedrollover/population)*100,2) 
	AS PCNTVaccinatedrollover
FROM vaccinatedPop
ORDER BY PCNTVaccinatedrollover DESC

-- Temporary table of the popoulation by their vaccinated percentage 
Drop Table if exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated
(
Location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations nvarchar(255),
Vaccinatedrollover numeric
)

insert into #PercentPopulationVaccinated
SELECT CDT.location,CDT.date,
	CDT.population,CVT.new_vaccinations,
		SUM(CONVERT(FLOAT,CVT.new_vaccinations)) 
			OVER(Partition BY CDT.location ORDER BY CDT.location,CDT.date) 
				AS Vaccinatedrollover
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
AND CVT.date=CDT.date 
WHERE CDT.continent is not null
ORDER BY 2,3 DESC
	
SELECT *,ROUND((Vaccinatedrollover/population)*100,2) AS PCNTVaccinatedrollover
FROM #PercentPopulationVaccinated
ORDER BY PCNTVaccinatedrollover DESC	


-- creating views
CREATE VIEW PercentPopulationVaccinated AS 
SELECT CDT.location,CDT.date,
	CDT.population,CVT.new_vaccinations,
		SUM(CONVERT(FLOAT,CVT.new_vaccinations)) 
			OVER(Partition BY CDT.location ORDER BY CDT.location,CDT.date) 
				AS Vaccinatedrollover
FROM CovidVaccination$ CVT
JOIN CovidDeaths$ CDT
ON CVT.location=CDT.location
AND CVT.date=CDT.date 
WHERE CDT.continent is not null
--ORDER BY 2,3 DESC
