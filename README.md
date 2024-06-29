# New-York-Payroll-Analysis
Final Project Deliverable for Ironhack Data Analytics Bootcamp. Explores payroll data provided by the City of New York. 

## Project Description
The purpose of this project was to use NYC Payroll data to analyze which city agencies were reporting and accruing the most overtime, and to make suggestions about changes that can be made. Skills I demonstrate in this project include gathering data, cleaning it using Python, analyzing the data in Python and MySql (both individually as well as together, more on that later), and building visualizations using Tableau. The project also required the use of softer skills such as time-management, problem solving, work-prioritization, and gathering and presenting valuable insight. 

## Data
[NYC Citywide Payroll Data][1] - Because New York City is an open-data city, they publish data regarding city operations for anyone to access and take advantage of. This annually updata dataset lists all city employees, their starting dates, position titles, salaries, employing agencies, hours, and working locations since 2014. It also reports regular and overtime hours and pay. More can be read on it by accessing the link. 

[City and Town Population Totals: 2020-2023][2] - This U.S. Census data lists the populations of all cities and towns in the United States (with a population of more that 20,000) for 2020-2023. This dataset was only used in Tableau, as it was relevant to my visualization building, but not to my analysis. 

[1]: https://data.cityofnewyork.us/City-Government/Citywide-Payroll-Data-Fiscal-Year-/k397-673e/about_data        "NYC Citywide Payroll Data"
[2]: https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-cities-and-towns.html                 "City and Town Population Totals: 2020-2023"

## Structure and Activities
### Data Cleaning
Data cleaning for this project was extensive and, aside from building my Tableau visualization, far and away occupied the greatest portion of my time. Some steps were easy, like the standardization of string columns contents to be all caps, the standardization of the dates columns using the pandas function to_datetime, and setting the column names to all be python and SQL friendly. Other cleaning activities included: 
* converting all **Work Location Borough** values that were not one of the main 5 boroughs to 'OTHER'.
* dropping name and initial columns after creation of **worker_id** column.
* reseting and creating a true index column
* creating columns providing more information about worker pay using mathematical operations from other columns
* adjusting column order to be more legible

I handled missing values as follows:
* **First Name**,**Last Name**, **Mid Init**: Some of these rows had no information in them because the City opted to withhold identifying information about certain individuals such as police, correction, and sanitation workers for their own protection. I deleted the Mid Init column, and filled missings in the other cells with "X"
* **Agency Start Date**, **Title Description** - Because there was no way to get accurate information for these rows, and because they needed to have something in them to be sent to a MySQL database, I just removed them. Given that there were only about 150 rows total where this was the case, it wasn't a significant loss. 
* **Work Location Borough**: This was the most troublesome column. I made two separate attempts to fill the columns more cleverly. First, I attempted to fill missings with the information from the cell above it if the location in the cells above and below were the same and if the employing agency in all three rows was the same. (The logic behind this being if this person is part of the same agency as the person listed before and after them, and the other two work in the same location, the person between them probably also works there.) However, when that only filled something like 50 rows, I took a more aggressive approach. I first added a new column that created a worker id for each and every individual by taking their initials, the initials of their employing agency, and their starting date (which would remain the same from year to year). (The remnants of this attempt, I am now realizing, are still visible in the data, because I kept the worker_id column for further analyzation that I never got to.) I then tried to fill the missings by having python look for the worker id to see if a working location showed up in any other of that employee's entries and use that. However, because that approach required sorting and then resorting my data back to it's original state, it ended up being far too memory-intensive and time-consuming to use. I ended up just filling all missing values in that column with 'WITHHELD'. Given that was the case for about 10% of my data, I didn't want to do that, but also given that the dataset still consisted of more than 4 million rows with accurate Working Location Borough data, I decided it was acceptable. 
