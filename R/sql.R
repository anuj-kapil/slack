# R
library(RPostgreSQL)
library(data.table)
library(RSQLite)

getwd()
con <- dbConnect(drv = dbDriver('PostgreSQL'),
                 host     = 'mdsislack.clnutj7nhgyn.us-east-2.rds.amazonaws.com',
                 port     = 5432, 
                 user     = 'dsp2019',
                 password = 'oZkK6vgRbvDK',
                 dbname = 'mdsislack')

users <- dbGetQuery(con, "select * from users")
channels <- dbGetQuery(con, "select * from channels")
messages <- dbGetQuery(con, "select * from messages")

print(users)
setDT(users)
users
dbDisconnect(con)

host = 'mdsislack.clnutj7nhgyn.us-east-2.rds.amazonaws.com'
port = 5432
user = 'dsp2019'
password = 'oZkK6vgRbvDK'

getwd()
slackdb <- dbConnect(RSQLite::SQLite(), "R/db/slackdb.sqlite")
dbWriteTable(slackdb, "users", users)
dbWriteTable(slackdb, "channels", channels)
dbWriteTable(slackdb, "messages", messages)

dbListTables(slackdb)


dbGetQuery(slackdb, 'SELECT * FROM users LIMIT 10')


max_posts_user <- 'select u.user_name
                    from
                    messages m
                    inner join users u
                    on m.user_id = u.user_id
                    group by 1
                    order by count(*) desc
                    limit 1'

dbGetQuery(slackdb, max_posts_user)

max_posts_channel <- 'select c.channel_name
                      from
                      messages m
                      inner join channels c
                      on m.channel_id = c.channel_id
                      group by 1
                      order by count(*) desc
                      limit 1'

dbGetQuery(slackdb, max_posts_channel)


max_posts_user_dam <- 'select u.user_name
                      from
                      messages m
                      inner join channels c on m.channel_id = c.channel_id
                      inner join users u on m.user_id = u.user_id
                      where c.channel_name = \'mdsi_dam_aut_18\'
                      group by 1
                      order by count(*) desc
                      limit 1'

dbGetQuery(slackdb, max_posts_user_dam)


all_msgs_2019_query <- 'select m.*, c.channel_name, c.channel_is_archived, u.user_name, u.user_is_bot
                        from
                        messages m
                        left join channels c on m.channel_id = c.channel_id
                        left join users u on m.user_id = u.user_id
                        WHERE datetime( m.message_timestamp, \'unixepoch\' ) >=  DATETIME(\'2019-01-01 00:00:00\')'


all_msgs_2019_query <- 'select m.message_timestamp, datetime( m.message_timestamp, \'unixepoch\' )
                        from
                        messages m
                        limit 10
                       '
dbGetQuery(slackdb, all_msgs_2019_query)

all_msgs_2019 <- dbGetQuery(slackdb, all_msgs_2019_query)

setDT(all_msgs_2019)
setDT(all_data)

all_data[is.na(user_name), unique(user_id)]

users[user_id == 'U1Q0FL1DZ']

all_data[is.na(channel_name)]

users[user_id == 'U1Q0FL1DZ']

users

messages

# -- User with maximum posts
# select u.user_name
# from 
# messages m
# inner join users u
# on m.user_id = u.user_id
# group by 1
# order by count(*) desc
# limit 1
# 
# -- Channel with maximum posts
# select c.channel_name
# from 
# messages m
# inner join channels c
# on m.channel_id = c.channel_id
# group by 1
# order by count(*) desc
# limit 1
# 
# 
# -- User with maximum posts in a particular channel
# select u.user_name
# from 
# messages m
# inner join channels c on m.channel_id = c.channel_id
# inner join users u on m.user_id = u.user_id
# where c.channel_name = 'mdsi_dam_aut_18'
# group by 1
# order by count(*) desc
# limit 1

dbDisconnect(slackdb)
#unlink("R/db/slackdb.sqlite")
# 
# db_file <- "slackdb.sqlite"
# 
# sqlite.driver <- dbDriver("SQLite")
# db <- dbConnect(sqlite.driver,
#                 dbname = db_file)
# 
# dbListTables(db)
# 
# dbDisconnect(db)

?dbConnect

head(users)
library(data.table)
setDT(users)
head(users)
users[, .N, by = user_timezone]

users[, .N, by = user_is_bot]

users[, .N, by = user_is_deleted]


users[user_is_bot==T]

users[user_timezone=='America/Los_Angeles']

setDT(channels)
head(channels)

channels[,.N, by = channel_is_archived]

head(messages)
setDT(messages)

messages[, message_date:= as.IDate(substr(message_timestamp, 1, 10))]

df$weeks <- cut(df[,"timeseq"], breaks="week")

library(lubridate)
library(dplyr)

cut(messages$message_date, breaks="week")
?cut

messages[, week:= cut.Date(message_date, breaks="week")]

plot_message_count <- messages[, .N, by = week]



?cumsum()

?.SD

library(ggplot2)
ggplot(plot_data, aes(x=as.IDate(message_date), y= weekly_users)) +
  geom_line()
  
?rollup()
library(zoo)

?rollsum()

summary(messages$week)
# CTE ?? how
# Defensive programming
# Assertions

x <- as.Date(1:1000, origin = "2000-01-01")
summary(x)
x <- cut(x, breaks = "quarter") 
summary(x)

messages[message_text%like%'how', unique(channel_id)]


