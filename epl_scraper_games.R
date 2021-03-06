#install.packages("rvest")
library("rvest")
library(data.table)
library(stringr)
library(dplyr)
library(stringi)


#date table for every day possible in season
itemizeDates <- function(startDate="08-11-17", endDate=Sys.Date(),
                         format="%m-%d-%y") {
  out <- seq(as.Date(startDate, format=format),
             as.Date(endDate, format=format), by="days")
  format(out, format)
}
dates = as.data.table(
  itemizeDates(startDate="08-11-17", endDate=Sys.Date())
)
dates$V1=format(strptime(dates$V1,"%m-%d-%y"),"%Y%m%d")

##every epl team code on nbc 
team_numbers = data.frame(team_number=c("21","1153","1150",'1133','25','90','28','1140','31',
                                        '32','33','34','36','37','1139','1141','39','97',
                                        '406','40'))

##making uniqueid for gamecode
gamecode= merge(team_numbers,dates)
gamecodetwo=gamecode
gamecode$full = if_else(stri_length(gamecode$team_number)==2, paste0('100',gamecode$team_number),
                        if_else(stri_length(gamecode$team_number)==3, paste0('10',gamecode$team_number),
                                paste0('1',gamecode$team_number)))
gamecodetwo$full = if_else(stri_length(gamecode$team_number)==2, paste0('200',gamecode$team_number),
                           if_else(stri_length(gamecode$team_number)==3, paste0('20',gamecode$team_number),
                                   paste0('2',gamecode$team_number)))
gamecodefinal = data.frame(gamecode = paste0(gamecode$V1,gamecode$full))
gamecodefinaltwo = data.frame(gamecode = paste0(gamecodetwo$V1,gamecodetwo$full))
gamecodefinal=rbind(gamecodefinal,gamecodefinaltwo)

game_vector <- gamecodefinal[['gamecode']]


##removing unnecessary tables
rm(gamecode, team_numbers, dates, gamecodefinal, gamecodefinaltwo, gamecodetwo)


#finding valid URLs
ListofURL = c()
count=0
z=0
starttime = Sys.time()
for (i in game_vector){
  z=z+1
  url = sprintf("http://scores.nbcsports.com/epl/boxscore.asp?gamecode=%s&show=pstats&ref=",game_vector[z])
  population <- url %>%
    read_html() %>%
    html_nodes(xpath='//*[@id="shsIFBBoxPlayerStats1"]/table[2]') %>%
    html_table(fill=TRUE)
  if(length(population)==0)next
  ListofURL = append(ListofURL,values =url)
  count=count+1
  print(url)
}
endtime=Sys.time()
print(endtime-starttime)
beepr::beep(1)

##scraper to put valid urls data into final df
count=0
for (i in ListofURL){
  url = ListofURL[count+1]
  population <- url %>%
    read_html() %>%
    html_nodes(xpath='//*[@id="shsIFBBoxPlayerStats1"]/table[2]') %>%
    html_table(fill=TRUE)
  population <- population[[1]]
  db= population[3:18,1:3]
  db = setNames(data.frame(t(db[,-2])), db[,2])
  colnames(db)[1] <- "team"
  db$team = str_sub(db$team, start= -3)
  db$date = str_sub(
    str_split_fixed(string = url, pattern = "gamecode=", n= 2)[,2], 
    end = 8)
  db$GoalsAllowed[1] = as.integer(as.character(db$Goals[2]))
  db$GoalsAllowed[2] = as.integer(as.character(db$Goals[1]))
  db$Opponent[1] = db$team[2]
  db$Opponent[2] = db$team[1]
  db$GameID = paste0(db$team[1],'v',db$team[2],db$date[1])
  db$home_away = if_else(db$team==db$team[1],'home','away')
  if(count==0){ 
    combineddb = db }
  else {
    combineddb= rbind(combineddb,db) }
  count = count+1
  print(count)
}
beepr::beep(sound=1)

#removing unnecessary tables
rm(db, population)

##checking data types
# str(combineddb)
# str(combineddb)
# combineddb$Shots = as.numeric(as.character(combineddb$Shots))
# combineddb$Passes = as.numeric(as.character(combineddb$Passes))
# combineddb$`Shots on Goal` = as.numeric(as.character(combineddb$`Shots on Goal`))



