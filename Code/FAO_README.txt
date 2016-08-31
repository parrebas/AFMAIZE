README FAO data extract scripts R.
v.26-8-2016 by Kees van Duijvendijk.

The script depends on the FAOSTAT en reshape2 libraries, and for examples also requires ggplot2, xts, and zoo.
The functions are stored in the script FAOsource.R, the examples in FAOexamples.R. R version 3.3.1 is used.

Steps:
1.  Place the scripts FAOsource.R and FAOexamples.R in the same (new) folder.
2.  Open the FAOexamples.R script en set the work directory to the main folder.
3.  Check if the libraries are available (use pacman for easy checking/installing).
4.  Run .FAO.all(). This opens a data frame with all available variables. Use filter to find a variable.
5.  Change keyword1 in .FAO.key() to keyword (use lowercase). Wildcards are used, so you can use a pattern:
    - it's better to search for 'fertil' than fertilizers, as sometimes the name differs (e.g. fertilizer).
6.  Run the .FAO.key() function and check the output ('keyword1'.csv) in the work directory.
7.  Change the 1 under the Included column to 0 if you want to exclude these from the data extraction.
8.  Run the FAO.datas lines (21-24) to subset data and remove special characters (needed to save to *.csv).
9.  Lines 29-39 extract all included datasets and create a new folder structure in the work directory:
    - the main folder is named after the keyword, the rest follows the existing FAOSTAT data structure.
10. Run the .FAO.sub() function, you can add a period or countries (with ISO). This will create a new csv:
    - data is ordered in a more efficient manner, data is stored in the output folder. Create own filename.

Extra:
Examples from line 51 require additional packages (select *.csv from output folder). More examples will follow.

Note:
Default search is for maize. Function .FAO.sub() requires interactive selection of *.csv folder (also examples).
Tested for keywords 'maize', 'wheat', 'rice', and 'fertilizer'. Output is not cleaned in any of the functions.

Contact:
Kees.vanDuijvendijk@wur.nl 