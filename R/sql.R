# R
library(RPostgreSQL)
con <- dbConnect(drv = dbDriver('PostgreSQL'),
                 host     = 'mdsislack.clnutj7nhgyn.us-east-2.rds.amazonaws.com',
                 port     = 5432, 
                 user     = 'dsp2019',
                 password = 'oZkK6vgRbvDK',
                 dbname = 'mdsislack')

users <- dbGetQuery(con, "select * from users")

print(users)

library(data.table)

setDT(users)
users
dbDisconnect(con)

host = 'mdsislack.clnutj7nhgyn.us-east-2.rds.amazonaws.com'
port = 5432
user = 'dsp2019'
password = 'oZkK6vgRbvDK'