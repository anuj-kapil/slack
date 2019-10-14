Slack Analysis
================

## Connect to Amazon RDS Slack database

``` r
# Connect to remote DB
con <- dbConnect(drv = dbDriver('PostgreSQL'),
                 host     = 'mdsislack.clnutj7nhgyn.us-east-2.rds.amazonaws.com',
                 port     = 5432, 
                 user     = 'dsp2019',
                 password = 'oZkK6vgRbvDK',
                 dbname = 'mdsislack')

# Extract all tables
users <- dbGetQuery(con, "select * from users")
channels <- dbGetQuery(con, "select * from channels")
messages <- dbGetQuery(con, "select * from messages")

# Disconnect from remote DB
dbDisconnect(con)
```

## Create a local SQLite database

``` r
getwd()

# Create a new sqlite database and new connection to the database
slackdb <- dbConnect(RSQLite::SQLite(), "db/slackdb.sqlite")

# Create table & Append data
dbWriteTable(slackdb, "users", users)
dbWriteTable(slackdb, "channels", channels)
dbWriteTable(slackdb, "messages", messages)

# Verify the tables created
dbListTables(slackdb)

# Disconnect from local database
dbDisconnect(slackdb)
```

## Query local SQLite database

``` r
# Database driver
sqlite_driver <- dbDriver("SQLite")

# Database file
slackdb_file <- "db/slackdb.sqlite"

# Database connection
slackdb <- dbConnect(sqlite_driver, dbname = slackdb_file)

# List all the tables
dbListTables(slackdb)
```

    ## [1] "channels" "messages" "users"

``` r
# Number of users (including bots)
total_users <- 'select count(*) as users
                from
                users
                '

dbGetQuery(slackdb, total_users)
```

    ##   users
    ## 1   363

``` r
# Number of users (including archived)
total_channels <- 'select count(*) as channels
                from
                channels
                '

dbGetQuery(slackdb, total_channels)
```

    ##   channels
    ## 1      128

``` r
# Number of posts
total_posts <- 'select count(*) as posts
                from
                messages
                '

dbGetQuery(slackdb, total_posts)
```

    ##   posts
    ## 1 28693

``` r
max_posts_user <- 'select u.user_name
                    from
                    messages m
                    inner join users u
                    on m.user_id = u.user_id
                    group by 1
                    order by count(*) desc
                    limit 1'

dbGetQuery(slackdb, max_posts_user)
```

    ##          user_name
    ## 1 Perry Stephenson

``` r
max_posts_channel <- 'select c.channel_name
                      from
                      messages m
                      inner join channels c
                      on m.channel_id = c.channel_id
                      group by 1
                      order by count(*) desc
                      limit 1'

dbGetQuery(slackdb, max_posts_channel)
```

    ##   channel_name
    ## 1        dev_r

``` r
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
```

    ##      user_name
    ## 1 Alex Scriven

``` r
dbDisconnect(slackdb)
```

## Data Analysis in R

``` r
# Database driver
sqlite_driver <- dbDriver("SQLite")

# Database file
slackdb_file <- "db/slackdb.sqlite"

# Database connection
slackdb <- dbConnect(sqlite_driver, dbname = slackdb_file)

# List all the tables
dbListTables(slackdb)
```

    ## [1] "channels" "messages" "users"

``` r
# Bring data from SQLite database in to R
all_msgs_2019_query <- 'select m.*, c.channel_name, c.channel_is_archived, u.user_name, u.user_is_bot
                        from
                        messages m
                        left join channels c on m.channel_id = c.channel_id
                        left join users u on m.user_id = u.user_id
                        WHERE datetime( m.message_timestamp, \'unixepoch\' ) >=  DATETIME(\'2019-01-01 00:00:00\')'

all_msgs_2019 <- dbGetQuery(slackdb, all_msgs_2019_query)

dbDisconnect(slackdb)

# 90 days active users and messages counts
setDT(all_msgs_2019)

all_msgs_2019[, message_date:= as.IDate(as.POSIXct(message_timestamp,origin="1970-01-01",tz="UTC"))]

all_msgs_2019[, week:= cut.Date(message_date, breaks="week")]

plot_data <- all_msgs_2019[, .(daily_msgs = .N, daily_users = uniqueN(user_id)), by = message_date]

setorderv(plot_data, "message_date")
plot_data[, weekly_msgs := rollsumr(daily_msgs, k = 7, fill = NA)]
plot_data[, weekly_users := rollsumr(daily_users, k = 7, fill = NA)]

# Plot Active Users (Weekly)
ggplot(plot_data, aes(x=as.IDate(message_date), y= weekly_users)) +
  geom_line() + 
  theme(panel.background = element_blank(), axis.line = element_line(colour = "grey"), plot.title = element_text(hjust = 0.5))+
  labs(x = 'Date', y = 'Number of Users') +
  ggtitle("Weekly Active Users")
```

![](slack_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r
# Plot Active Users (Daily)
ggplot(plot_data, aes(x=as.IDate(message_date), y= daily_users)) +
  geom_line() + 
  theme(panel.background = element_blank(), axis.line = element_line(colour = "grey"), plot.title = element_text(hjust = 0.5))+
  labs(x = 'Date', y = 'Number of Users') +
  ggtitle("Daily Active Users")
```

![](slack_files/figure-gfm/unnamed-chunk-4-2.png)<!-- -->

``` r
# Plot All Msgs (weekly)
ggplot(plot_data, aes(x=as.IDate(message_date), y= weekly_msgs)) +
  geom_line() + 
  theme(panel.background = element_blank(), axis.line = element_line(colour = "grey"), plot.title = element_text(hjust = 0.5))+
  labs(x = 'Date', y = 'Number of Messages') +
  ggtitle("Weekly Messages")
```

![](slack_files/figure-gfm/unnamed-chunk-4-3.png)<!-- -->

``` r
# Plot All Msgs (daily)
ggplot(plot_data, aes(x=as.IDate(message_date), y= daily_msgs)) +
  geom_line() + 
  theme(panel.background = element_blank(), axis.line = element_line(colour = "grey"), plot.title = element_text(hjust = 0.5))+
  labs(x = 'Date', y = 'Number of Messages') +
  ggtitle("Daily Messages")
```

![](slack_files/figure-gfm/unnamed-chunk-4-4.png)<!-- -->

## Data Analysis in Python

``` python
import pandas as pd
import matplotlib.pyplot as plt

# Data Frame
all_msgs_2019 = pd.DataFrame(r.all_msgs_2019)


# Top 10 Users - 90 days
all_msgs_2019[all_msgs_2019["user_name"] != 'NA']["user_name"].value_counts().nlargest(10).plot.bar()
plt.tight_layout()
plt.show()

# Top 10 Channels - 90 days
```

![](slack_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

``` python
all_msgs_2019["channel_name"].value_counts().nlargest(10).plot.bar()
plt.tight_layout()
```

    ## /Users/anuj/anaconda3/bin/python:1: UserWarning: Tight layout not applied. The bottom and top margins cannot be made large enough to accommodate all axes decorations.

``` python
plt.show()
```

![](slack_files/figure-gfm/unnamed-chunk-5-2.png)<!-- -->
