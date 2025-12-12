This project aims to analyze the relationship between transit accessibility and poverty in Chicago. 
The goal is to identify patterns in the distribution of CTA L stations across different neighborhoods (Census tracts) and assess how these patterns are related to socio-economic factors like poverty, median income, and public transportation usage. 
The analysis will help identify potential areas where there is a lack of transit access, particularly in high-poverty neighborhoods, and provide insights into how resources could be allocated more equitably.


Scripts:
Data Download and Preprocessing: The data_download.R script loads datasets from public APIs, including CTA L station data and U.S. Census data for Cook County. It cleans and formats the data for analysis.
Data Analysis: The data_analysis.R script performs data wrangling, calculates additional variables such as poverty rate and transit share, and aggregates data by Census tract.
Visualization: The visualization.R script uses the tmap package to create interactive maps visualizing transit station distribution, median income, and other socio-economic variables across Census tracts.

Datasets:
CTA L Station Data: Data on the locations of CTA L stations in Chicago, retrieved from the City of Chicago’s open data portal.
Census Data (Cook County): Data from the U.S. Census Bureau’s American Community Survey (ACS), including variables such as population, poverty rate, median income, and public transportation commute data.
