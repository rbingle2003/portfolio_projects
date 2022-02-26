/*
COVID 19 Data Exploration Project

Skills used: Windows Import, Queries, Joins, Converting Data Types, Aggregate Functions, Creating Views

*/

SELECT *
FROM portfolio_project..covid_deaths$
WHERE continent is not null --Continent data was included among country data
ORDER BY 3,4

-- Select Data that is required for the upcoming exploration

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio_project..covid_deaths$
WHERE continent is not null
ORDER BY 1,2

-- Examine Total Cases vs Total Deaths
-- Shows percentage of deaths per country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM portfolio_project..covid_deaths$
WHERE continent is not null
ORDER BY 1,2

-- Examine Total Cases vs Total Deaths in United States
-- Shows percentage of deaths in United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM portfolio_project..covid_deaths$
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Examine Total Cases vs Total Population in United States
-- Shows percentage of total cases compared to total population in the United States

SELECT location, date, total_cases, population, (total_cases/population)*100 AS COVID_percentage
FROM portfolio_project..covid_deaths$
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Examine Countries with Highest Infection Rates
-- Shows countries with highest infection percentages in descending order

SELECT location, population, MAX(total_cases) AS peak_infection_count, MAX((total_cases/population))*100 AS peak_COVID_percentage
FROM portfolio_project..covid_deaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY peak_COVID_percentage DESC

-- Examine Countries with Highest Death Rates by Country
-- Shows countries with highest death rates in descending order

SELECT location, MAX(CAST(total_deaths as INT)) as total_death_count --total_death data is coded as VARCHAR
FROM portfolio_project..covid_deaths$
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC

-- Examine Continents with Highest Death Rates
-- Shows continents with highest death rates in descending order

SELECT continent, MAX(CAST(total_deaths as INT)) as total_death_count
FROM portfolio_project..covid_deaths$
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC

-- Total Deaths Worldwide Up Until 25/2/22

SELECT SUM(new_cases) AS total_global_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS death_percent
FROM portfolio_project..covid_deaths$
WHERE continent is not null
ORDER BY 1,2

-- Compare Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccine_total --Stops rolling count at new location, use BIGINT not INT due to overflow error
FROM portfolio_project..covid_deaths$ AS dea
JOIN portfolio_project..covid_vaccinations$ AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3 

-- Total Vaccination Percentage by Country
-- Using CTE to perform Calculation on Partition By in previous query

With pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_vaccine_total)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccine_total --Stops rolling count at new location, use BIGINT not INT due to overflow error
FROM portfolio_project..covid_deaths$ AS dea
JOIN portfolio_project..covid_vaccinations$ AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rolling_vaccine_total/population)*100 as rolling_vaccination_percent
FROM pop_vs_vac

--Create View to store data for visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccine_total --Stops rolling count at new location, use BIGINT not INT due to overflow error
FROM portfolio_project..covid_deaths$ AS dea
JOIN portfolio_project..covid_vaccinations$ AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null
