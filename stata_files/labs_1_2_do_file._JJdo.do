********************************************************************************
* 			Regional Economics 2022: Labs 1 and 2							   *
* 					Author: Vinzent Ostermeyer								   *
********************************************************************************

********************************************************************************
* 			Install additional programs and set-up							   *
********************************************************************************

//to run do-files click the "run-button" or highlight the lines of code and hit ctrl + D (Windows) or shift + cmd + D (Mac)

ssc install spmap, replace
ssc install geo2xy, replace
ssc install shp2dta, replace
ssc install schemepack, replace
ssc install scheme-burd, replace
ssc install colrspace, replace
ssc install palettes, replace
ssc install egenmore, replace
ssc install outreg2, replace

// always comment your code

cd "" // set your directory
help // Stata's help function; cf. also the web or Statalist
version 16.1 // version control

********************************************************************************
* 			Import of Roses-Wolf dataset from Excel into Stata 				   *
********************************************************************************

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A1 Regional GDP") firstrow cellrange(A6:O179) clear // import Excel sheet
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A1 Regional GDP") firstrow cellrange(A6:O179) clear allstring // we import each sheet in the Excel file separately and save it as one file
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)
destring year_*, replace
// if there are non-numerical values in a string you cannot use destring and should not use the force-option as it would create missing values
// a better approach is to check all cases that are non-numerical and replace them (e.g. change "one" to "1")
// tab var1 if missing(real(var1))
// replace var1 ... if ...
// destring var1, replace
help reshape
reshape long year_, i(NUTSCodes Region Countrycurrentborder) j(year)
rename year_ regional_gdp_millions
save regional_gdp, replace // never overwrite your raw data; e.g., save a copy in a different folder before the analysis

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A1b Regional GDP (2011PPP)") firstrow cellrange(A6:O179) clear allstring // repetition of the steps above for each sheet
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)
destring year_*, replace
reshape long year_, i(NUTSCodes Region Countrycurrentborder) j(year)
rename year_ regional_gdp_2011_ppp_millions
save regional_gdp_2011_ppp, replace

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A3 Population") firstrow cellrange(A6:O179) clear allstring
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)
destring year_*, replace
reshape long year_, i(NUTSCodes Region Countrycurrentborder) j(year)
rename year_ population_thousands
save population, replace

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A4 Employment Share Agriculture") firstrow cellrange(A6:O179) clear allstring
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)
destring year_*, replace
reshape long year_, i(NUTSCodes Region Countrycurrentborder) j(year)
rename year_ employment_share_agriculture
save share_agriculture, replace

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A5 Employment Share Industry") firstrow cellrange(A6:O179) clear allstring
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)
destring year_*, replace
reshape long year_, i(NUTSCodes Region Countrycurrentborder) j(year)
rename year_ employment_share_industry
save share_industry, replace

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A6 Employment Share Services") firstrow cellrange(A6:O179) clear allstring
rename (D E F G H I J K L M N O) (year_1900 year_1910 year_1925 year_1938 year_1950 year_1960 year_1970 year_1980 year_1990 year_2000 year_2010 year_2015)
destring year_*, replace
reshape long year_, i(NUTSCodes Region Countrycurrentborder) j(year)
rename year_ employment_share_services
save share_services, replace

import excel using RosesWolf_RegionalGDP_v6.xlsx, sheet("A2 Area") firstrow cellrange(A6:D179) clear allstring
rename D area_km2
destring area_km2, replace
save area_km2, replace

********************************************************************************
* 			Importing the shapefiles										   *
********************************************************************************

clear // clear the dataset in memory

shp2dta using regions_nuts2, database(regions) coordinates(nutscoord) genid(_ID) replace

use regions, clear // fixing the identifier of the NUTS_Codes so that the merge below works for all regions in the dataset
replace NUTS_CODE = "AT12+AT13" if NUTS_CODE == "AT123"
replace NUTS_CODE = "DE71+DE72" if NUTS_CODE == "DE712"
replace NUTS_CODE = "DE91+DE92" if NUTS_CODE == "DE912"
save regions, replace

use nutscoord, clear // we use the Albers projection; every projection looks a bit different as highlighted e.g. here https://www.statalist.org/forums/forum/general-stata-discussion/general/1306288-legend-in-spmap
scatter _Y _X
help geo2xy // you can try the other projections as well
geo2xy _Y _X, proj(albers) replace
scatter _Y _X
save nutscoord, replace

********************************************************************************
* 			Merge shapefiles and data together   							   *
********************************************************************************

use regional_gdp, clear // we merge all created files together
help merge
merge 1:1 NUTSCodes year using regional_gdp_2011_ppp // this is a 1:1 merge
drop _merge
merge 1:1 NUTSCodes year using population, assert(match) nogen
merge 1:1 NUTSCodes year using share_agriculture, assert(match) nogen
merge 1:1 NUTSCodes year using share_industry, assert(match) nogen
merge 1:1 NUTSCodes year using share_services, assert(match) nogen
merge m:1 NUTSCodes using area_km2, assert(match) nogen // this is a m:1 merge; there is also a 1:m merges; m:m merges are a bad idea
rename NUTSCodes NUTS_CODE
merge m:1 NUTS_CODE using regions
drop if _merge == 2 // we keep all regions that are merged and delete those for which we have geographical information but no data
drop _merge
order _ID, after(NUTS_CODE)

********************************************************************************
* 			Formatting and Creating Variables   							   *
********************************************************************************

rename Countrycurrentborder country
rename (Region regional_gdp_millions regional_gdp_2011_ppp_millions population_thousands area_km2) (region regional_gdp_1990 regional_gdp_2011 regional_population regional_area) // cleaning the dataset

replace regional_gdp_1990 = regional_gdp_1990 * 1000000
replace regional_gdp_2011 = regional_gdp_2011 * 1000000
replace regional_population = regional_population * 1000

bysort country year: egen national_gdp_1990 = total(regional_gdp_1990)
bysort country year: egen national_population = total(regional_population)

gen national_gdp_cap_1990 = national_gdp_1990 / national_population
gen regional_gdp_cap_1990 = regional_gdp_1990 / regional_population
gen regional_gdp_cap_2011 = regional_gdp_2011 / regional_population
sort country region year

gen population_density = regional_population / regional_area // you often have to calculate new variables, which you then can map

egen q_regional_gdp_cap_1990 = xtile(regional_gdp_cap_1990), n(5) by(year) // you can change the number of groups
sort country region year

bysort year: egen mean_gdp_cap_eu = mean(regional_gdp_cap_1990)
sort country region year
gen relative_gdp_cap_eu = regional_gdp_cap_1990 / mean_gdp_cap_eu

bysort year country: egen mean_gdp_cap_country = mean(regional_gdp_cap_1990)
sort country region year
gen relative_gdp_cap_country = regional_gdp_cap_1990 / mean_gdp_cap_country

label variable _ID "Region ID"
label variable year "Year"
label variable country "Country in Current Borders"
label variable regional_gdp_1990 "Regional GDP in 1990 International Dollars"
label variable regional_population "Regional Population"
label variable employment_share_agriculture "Regional Share of Employment in Agriculture"
label variable employment_share_industry "Regional Share of Employment in Industry"
label variable employment_share_services "Regional Share of Employment in Services"
label variable regional_area "Area in KM2"
label variable national_gdp_1990 "National GDP in 1990 International Dollars"
label variable national_gdp_cap_1990 "National GDP per Capita in 1990 International Dollars"
label variable regional_gdp_cap_1990 "Regional GDP per Capita in 1990 International Dollars"
label variable national_population "National Population"

format region NUTS_CODE %20s

save regional_dataset, replace

********************************************************************************
* 						Summary statistics									   *
********************************************************************************

use regional_dataset, clear

tab country
tab region

summarize national_gdp_cap_1990 if year == 1950, detail
summarize regional_gdp_cap_1990 if year == 1950, detail
summarize regional_gdp_cap_1990 if year == 2000, detail

outreg2 using sum_table.doc, replace sum(log) keep(regional_gdp_cap_1990) eqkeep(N mean sd) label // to learn more about outreg2: https://www.princeton.edu/~otorres/Outreg2.pdf
outreg2 if year == 1950 using sum_table_1950.doc, replace sum(log) keep(regional_gdp_cap_1990) eqkeep(N mean sd) label

sort year regional_gdp_cap_1990
br region country regional_gdp_cap_1990 if year == 1900 // compare with table 2.6 in course book
br region country regional_gdp_cap_1990 if year == 2010

********************************************************************************
* 						           Basic Maps    			   				   *
********************************************************************************

// note: try to code everything and use the graph-editor only in exceptional cases

use regional_dataset, clear

help spmap

spmap using "nutscoord.dta" if year == 1950, id(_ID)

spmap using "nutscoord.dta" if year == 1960, id(_ID) ///
	title("My first Map", size(large)) ///
	note("Source: Rosés-Wolf (2020)", size(vsmall) pos(5))
	
spmap national_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID)

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2)

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2)

help format // you can format any variable
format regional_gdp_cap_1990 %12.0fc // 12 numbers left of the decimal point; 0 to the right; commas to denote thousands
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2)

// if there is a /// you have to highlight all lines of that specific task and run them together

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1970, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1970", size(medium)) ///
	osize(0.02 ..) ocolor(gs8 ..)
	
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1950 ", size(medium)) ///
	osize(0.02 ..) ocolor(gs8 ..) ///
	clmethod(custom) clbreaks(0 (1000) 12000)

summarize regional_gdp_cap_1990 if year == 1950, detail

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(1) ///
	title("Regional GDP per Capita - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 3000 (1000) 6000 12000)
	
spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Employment Share Industry - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)

spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Employment Share Industry - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.2) 0.8) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)
	
spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legstyle(2) ///
	title("Employment Share Industry - 1950", size(large)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.2) 0.8) ///
	legend(pos(9) size(medium) rowgap(1.5) label(5 "60-80 %") label(4 "40-60 %") ///
	label(3 "20-40 %") label(2 "0-20 %") label(1 "No data")) ///
	ndfcolor(gray) ndocolor(white ..) ndsize(0.02 ..)

graph export share_industry_1950.png, replace width(2000) // save a map as png file to work with it in other programs

spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legstyle(2) ///
	title("1950", size(large)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.1) 0.8) ///
	legend(pos(9) region(fcolor(gs15)) size(2.5)) legtitle("1 = 100%") ///
	ndfcolor(gray) ndocolor(white ..) ndsize(0.02 ..) ///
	name(share_industry_1950, replace)
	
spmap employment_share_industry using "nutscoord.dta" if year == 2000, id(_ID) fcolor(Blues2) legstyle(2) ///
	title("2000", size(large)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.1) 0.8) ///
	legend(off) ///
	ndfcolor(gray) ndocolor(white ..) ndsize(0.02 ..) ///
	name(share_industry_2000, replace)
	
graph combine share_industry_1950 share_industry_2000
	
graph combine share_industry_1950 share_industry_2000, graphregion(color(white)) ///
	title(Share Empoyment Industry) ///
	note(Source: Rosés-Wolf (2020), size(small) position(5))

graph combine share_industry_1950 share_industry_2000, graphregion(color(white)) ///
	title(Share Empoyment Industry) ///
	note(Source: Rosés-Wolf (2020), size(small) position(5)) ///
	scheme(s2mono)
	
graph export share_industry_1950_2000.png, replace width(2000)

********************************************************************************
* 				         Comparing Maps Over Time			   				   *
********************************************************************************

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (2000) 12000)
	
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 2010, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 2010", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (2000) 12000)

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..)
	
// clmethod(quantile) is actually the default classification method
	
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(quantile) name(graph_1950, replace)
	
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 2010, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 2010", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(quantile) name(graph_2010, replace)

graph combine graph_1950 graph_2010
	
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(quantile) clnumber(5)

spmap q_regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	title("Regional GDP per Capita - 1950", size(medium)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (1) 5)
	
spmap relative_gdp_cap_eu using "nutscoord.dta" if year == 1900, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	osize(0.02 ..) ocolor(white ..) title(1900) ///
	clmethod(custom) clbreaks(0 0.8 1 1.2 3) ///
	name(graph_1900, replace)

spmap relative_gdp_cap_eu using "nutscoord.dta" if year == 2010, id(_ID) fcolor(Blues2) legend(pos(9)) legstyle(2) ///
	osize(0.02 ..) ocolor(white ..) title(2010) ///
	clmethod(custom) clbreaks(0 0.8 1 1.2 3) ///
	name(graph_2010, replace)

graph combine graph_1900 graph_2010 // compare with maps 2.4a and 2.4b in the course book

// a discussion about the pros and cons of the different classification methods: https://pro.arcgis.com/en/pro-app/latest/help/mapping/layer-properties/data-classification-methods.htm

********************************************************************************
* 					    Looking at One Country     			   				   *
********************************************************************************

spmap employment_share_industry using "nutscoord.dta" if year == 1950 & country == "Sweden", id(_ID)

spmap employment_share_industry using "nutscoord.dta" if year == 1950 & country == "Sweden", id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(3.5)) legstyle(2) ///
	title("Employment Share Industry - 1950", size(6)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)

spmap relative_gdp_cap_country using "nutscoord.dta" if year == 1990 & country == "Switzerland", id(_ID) ///
	fcolor(Blues2) legend(pos(5)) legstyle(1) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 0.8 1 1.2 3)

// pay attention to what is included in your dataset especially when calculating relative variables

spmap employment_share_industry using "nutscoord.dta" if year == 1950 & country == "Sweden" | year == 1950 & country == "Denmark", id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(3.5)) legstyle(2) ///
	title("Employment Share Industry - 1950", size(6)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)

spmap employment_share_industry using "nutscoord.dta" if year == 1950 & (country == "Sweden" | country == "Denmark"), id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(3.5)) legstyle(2) ///
	title("Employment Share Industry - 1950", size(6)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)

gen group_1 = 0
replace group_1 = 1 if country == "Sweden" | country == "Denmark"

spmap employment_share_industry using "nutscoord.dta" if year == 1950 & group_1 == 1, id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(3.5)) legstyle(2) ///
	title("Employment Share Industry - 1950", size(6)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)

gen group_2 = (country == "Sweden" | country == "Denmark")
assert group_1 == group_2

drop if country != "Sweden" // sometimes it is easier to drop everything but the observations you need
keep if country == "Sweden"
br

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(3.5)) legstyle(2) ///
	title("Regional GDP per Capita - 1950", size(6)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)
	
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(3.5)) legstyle(2) ///
	title("Regional GDP per Capita", size(8)) ///
	subtitle("Sweden, 1950", size(6)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..)

spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) ///
	fcolor(Blues2) legend(pos(5) size(2)) legstyle(2) ///
	title("Regional GDP per Capita", size(6)) ///
	subtitle("Sweden, 1950", size(4)) ///
	osize(0.02 ..) ocolor(white ..) ///
	ndfcolor(gray) ndocolor(none ..) ndsize(0.02 ..) ///
	ysize(8) xsize(7)

********************************************************************************
* 					 Experimenting with Colors    			   				   *
********************************************************************************

use regional_dataset, clear

help spmap // look at fcolor
help colorstyle

spmap national_gdp_cap_1990 using "nutscoord.dta" if year == 1950, id(_ID) fcolor(Heat)

help colorpalette

colorpalette viridis, n(8) nograph
local colors `r(p)'
spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor("`colors'") legstyle(2) ///
	title("1950", size(large)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.1) 0.8) ///
	legend(pos(9) region(fcolor(gs15)) size(2.5)) legtitle("1 = 100%") ///
	ndfcolor(gray) ndocolor(white ..) ndsize(0.02 ..)

colorpalette viridis, n(8) nograph reverse
local colors `r(p)'
spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor("`colors'") legstyle(2) ///
	title("1950", size(large)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.1) 0.8) ///
	legend(pos(9) region(fcolor(gs15)) size(2.5)) legtitle("1 = 100%") ///
	ndfcolor(gray) ndocolor(white ..) ndsize(0.02 ..)
	
colorpalette viridis, n(8) nograph reverse
local colors `r(p)'
spmap employment_share_industry using "nutscoord.dta" if year == 1950, id(_ID) fcolor("`colors'") legstyle(2) ///
	title("1950", size(large) color(white)) ///
	osize(0.02 ..) ocolor(white ..) ///
	clmethod(custom) clbreaks(0 (0.1) 0.8) ///
	legend(pos(9) region(fcolor(navy)) color(white) size(2.5)) legtitle("1 = 100%") ///
	ndfcolor(gray) ndocolor(white ..) ndsize(0.02 ..) graphregion(color(navy))

********************************************************************************
* 					    Looping, Globals and Locals   				           *
********************************************************************************

foreach var of varlist employment_share_industry employment_share_services {
	foreach i of numlist 1950 (10) 1970 {
		spmap `var' using "nutscoord.dta" if year == `i', id(_ID)
	}
}
	
global varlist employment_share_industry employment_share_services
foreach var of varlist $varlist {
	foreach i of numlist 1950 (10) 1970 {
		spmap `var' using "nutscoord.dta" if year == `i', id(_ID) name(`var'_`i', replace)
	}
}
graph combine employment_share_industry_1950 employment_share_industry_1960 employment_share_industry_1970 

macro drop _all // clears globals; useful because they remain active in the background, which could interfer with other active Stata sessions

local a "Hello"
local b "World"
di "`a' `b'"

local x = 1
local y = 2
di `x' + `y'

********************************************************************************
* 				       			Graphs						   				   *
********************************************************************************

twoway line employment_share_agriculture year if region == "Sydsverige"

replace region = "Southern Sweden" if region == "Sydsverige"

twoway line employment_share_agriculture year if region == "Southern Sweden"

twoway line employment_share_agriculture year if country == "Sweden", by(region)

twoway line employment_share_industry employment_share_services year if country == "Sweden", by(region)

replace employment_share_industry = employment_share_industry * 100
replace employment_share_services = employment_share_services * 100

twoway line employment_share_industry employment_share_services year if country == "Sweden", ///
	by(region) xlabel(1900 (50) 2000)

twoway line employment_share_industry employment_share_services year if country == "Sweden", ///
	by(region, note("")) subtitle(, lstyle(none) size(small)) ///
	xlabel(1900 (50) 2000) ylabel(0 (40) 80)

twoway line employment_share_industry employment_share_services year if country == "Sweden", ///
	by(region, note("")) subtitle(, lstyle(none) size(small)) ///
	xlabel(1900 (50) 2000) ylabel(0 (40) 80) ytitle(Share in %) ///
	legen(size(vsmall))
	
twoway line employment_share_industry employment_share_services year if country == "Sweden", ///
	by(region, note("")) subtitle(, lstyle(none) size(small)) ///
	xlabel(1900 (50) 2000) ylabel(0 (40) 80) ytitle(Share in %) ///
	legend(size(vsmall)) scheme(burd)

twoway line employment_share_industry employment_share_services year if country == "Sweden", ///
	by(region, note("")) subtitle(, lstyle(none) size(small)) ///
	xlabel(1900 (50) 2000) ylabel(0 (40) 80) ytitle(Share in %) ///
	legend(size(vsmall)) scheme(swift_red)

help scheme
help schemepack

********************************************************************************
* 						      By Request: Labelling		    				   *
********************************************************************************

use nutscoord, clear // by request: to label the regions
bysort _ID: egen mean_x = mean(_X)
bysort _ID: egen mean_y = mean(_Y)
keep _ID mean_x mean_y
duplicates drop
merge 1:m _ID using regional_dataset
keep if _merge == 3
keep if country == "France"
keep _ID mean_x mean_y region
duplicates drop
save labels_regions, replace
use regional_dataset, clear
keep if country == "France"
spmap regional_gdp_cap_1990 using "nutscoord.dta" if year == 1950, ///
	id(_ID) fcolor(Oranges) ndfcolor(gray) ///
	osize(0.02 ..) ocolor(gs8 ..) legend(color(white) pos(7)) legstyle(2) ///
	label(data(labels_regions) xcoord(mean_x) ycoord(mean_y) ///
	label(region) size(*0.5) length(50) color(grey)) graphregion(color(navy))
	// to have multiple lines of labels see https://www.statalist.org/forums/forum/general-stata-discussion/general/1395567-how-to-add-state-names-and-labels-using-spmap

********************************************************************************
* 						      Extra Material    		    				   *
********************************************************************************

bysort country year: egen test_1 = total(regional_gdp_1990) // pay attention to the sorting when calculating totals
bysort country (year): egen test_2 = total(regional_gdp_1990)
br country region year regional_gdp_1990 national_gdp_1990 test_1 test_2
assert test_1 != test_2 // useful to test whether a condition holds (or not)
assert test_1 == national_gdp_1990

replace employment_share_agriculture = employment_share_agriculture * 100
bysort country region (year): gen change_share_agriculture_1 = employment_share_agriculture[_n] - employment_share_agriculture[_n-1] // cf. also the time operators l., f. and d. as well as xtset and tsset

// https://datacatalog.worldbank.org/search/dataset/0038272 : link to world maps; can be converted into Stata format; use e.g. "World Country Polygons - Very High Definition"; already contains some data
// https://data.worldbank.org/ : other World Bank data; can e.g. be matched to the maps
// read these articles on how to make good maps and discuss https://www.bloomberg.com/news/articles/2015-06-25/how-to-avoid-being-fooled-by-bad-maps https://mgimond.github.io/Spatial/good-map-making-tips.html
