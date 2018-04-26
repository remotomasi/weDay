#!/bin/bash
# **************************************************************************
# Creator: Remo Tomasi
#
# Weather forecasting using infos from "Weather unlocked"
#
# NOTE: we need to install jq
#
# **************************************************************************
# set the environment: these files as useful to save and use temporary datas

# test if directories DATAS, HTML, IMAGES don't exist and create them
if [ ! -d "DATAS" ]; then mkdir DATAS; fi
if [ ! -d "HTMLS" ]; then mkdir HTMLS; fi
if [ ! -d "IMAGES" ]; then mkdir IMAGES; fi

if [ -e DATAS/weDay.json ]; then rm DATAS/weDay.json; fi
if [ -e DATAS/dati.csv ]; then rm DATAS/dati.csv; fi
if [ -e DATAS/finalDatas.csv ]; then rm DATAS/finalDatas.csv; fi
if [ -e DATAS/tmp.csv ]; then rm DATAS/tmp.csv; fi

# Obtain today date
DATE=$(date +%d%m%Y)

echo -e "Insert latitude and longitude (separated by spaces, i.e.: 60.32 21.03)"
read par mer

# download of json datas and save the wjson file
curl "http://api.weatherunlocked.com/api/forecast/$par,$mer?app_id=398aa617&app_key=0d99b683a850f28230471e544d329d2d" > DATAS/weDay.json

# loop to obtain infos from the json file: here we use jq
i=0
l=0
while [ $i -lt `jq '.Days | length-1' DATAS/weDay.json` ]; do
  while [ $l -lt `jq '.Days['$i'].Timeframes | length' DATAS/weDay.json` ]; do
    cat DATAS/weDay.json | jq --raw-output .Days["$i"].Timeframes[$l].date,.Days["$i"].Timeframes[$l].time,.Days["$i"].Timeframes[$l].temp_c,.Days["$i"].Timeframes[$l].dewpoint_c,.Days["$i"].Timeframes[$l].humid_pct,.Days["$i"].Timeframes[$l].cloud_low_pct,.Days["$i"].Timeframes[$l].cloud_mid_pct,.Days["$i"].Timeframes[$l].cloud_high_pct,.Days["$i"].Timeframes[$l].cloudtotal_pct,.Days["$i"].Timeframes[$l].rain_mm,.Days["$i"].Timeframes[$l].prob_precip_pct,.Days["$i"].Timeframes[$l].precip_mm,.Days["$i"].Timeframes[$l].snow_mm,.Days["$i"].Timeframes[$l].snow_accum_cm,.Days["$i"].Timeframes[$l].winddir_compass,.Days["$i"].Timeframes[$l].winddir_deg,.Days["$i"].Timeframes[$l].windspd_kmh,.Days["$i"].Timeframes[$l].windgst_kmh,.Days["$i"].Timeframes[$l].slp_mb,.Days["$i"].Timeframes[$l].vis_km,.Days["$i"].Timeframes[$l].wx_desc >> DATAS/dati.csv
    #.Days["$i"].temp_max_c,.Days["$i"].temp_min_c,.Days["$i"].precip_total_mm,.Days["$i"].prob_precip_pct,.Days["$i"].snow_total_mm,.Days["$i"].rain_total_mm,.Days["$i"].humid_max_pct,.Days["$i"].humid_min_pct,.Days["$i"].slp_max_mb,.Days["$i"].slp_min_mb,.Days["$i"].windspd_max_kmh,.Days["$i"].windgst_max_kmh >> DATAS/dati.csv
    echo -e "\t" >> DATAS/dati.csv
    let l+=1
  done
  l=0
  let i+=1
done

# finishing the informations formatting datas in various formats
cat DATAS/dati.csv | tr '\n' ',' | tr '\t' '\n' | tr ',' '\t' | tr ' ' '-' | tr 'T' '\t' | tr '\t' ' ' >> DATAS/finalDatas.csv
#sed -i '2d' DATAS/finalDatas.csv                                                    # first two lines

awk 'BEGIN{FS=OFS=" "}{print $1,int($2/100),$3,$4,$5,$6,$7,$8,$9,$10,gsub(/"<1"/, "0", $11),$12,$13,$14,$15,$16,$17,$18,$19,$20,$21}' DATAS/finalDatas.csv > DATAS/tmp.csv  # positioning of the columns:
                                                                                                                                                                    # deletioning of the last digits for the hours
                                                                                                                                                                    # replacement of the chr '<' to ''  --> '<1' => '1'

# creation of the first line (columns)
echo -e "Date Time Temp DewPoint Hum CloudLow CloudMid CloudHigh CloudTot RainMM ProbPrec PrecMM SnowMM SnowTotCM WindDir WindDirDeg WindSpeed WindGst Press Vis Desc" > DATAS/finalDatas.csv
cat DATAS/tmp.csv >> DATAS/finalDatas.csv
#head -6 DATAS/tmp.csv > finalDatas.csv

cat DATAS/tmp.csv > DATAS/tmp2.csv
awk '{ print $0, NR }' DATAS/tmp2.csv > DATAS/tmp.csv  # adding number of the line at the end of each line

./conv2htm.sh DATAS/tmp.csv > HTMLS/weatherForecast.html                 # csv to html conversion
./pressureWind.pg > IMAGES/weatherPressureWind.png
./tempDP.pg > IMAGES/weatherTempDP.png
./precip.pg > IMAGES/weatherPrecip.png
./cloud.pg > IMAGES/weatherClouds.png
./wind.pg > IMAGES/weatherWind.png
./pressure.pg > IMAGES/weatherPressure.png
./weather.pg > IMAGES/weatherForecast.png
