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
all_msgs_2019[, .(msg_count = .N, user_count = uniqueN(user_id)), by = channel_id]
```

    ##     channel_id msg_count user_count
    ##  1:  C5SQ1Q1UH        32          3
    ##  2:  C1E873E2E        53         10
    ##  3:  C1924SRPG       525         19
    ##  4:  CGQREKSBG       217         14
    ##  5:  C1NDAKX39       138         10
    ##  6:  C1CHS0P45        38          9
    ##  7:  C6HMFCW9K        84          1
    ##  8:  CGV3RUZ2S        22          6
    ##  9:  CH96CFF8E        22          3
    ## 10:  C192CUEH5       203         14
    ## 11:  CGRPA1FQS         9          6
    ## 12:  C18SWDACD       155         36
    ## 13:  C1ATW6P99        14          5
    ## 14:  CGV3BFTC1        17          3
    ## 15:  CGCFSE3FD        29         12
    ## 16:  C2L4ZHVHQ        12          2
    ## 17:  C1U4T4GCR        44         16
    ## 18:  C6YT8EK9S        31          2
    ## 19:  CGQ64P9QS        51         10
    ## 20:  CH8QYP7UP        10          6
    ## 21:  CH36QTYDA        22          4
    ## 22:  CGUV9MGUQ        18          7
    ## 23:  C1AR0J1K6        20          9
    ## 24:  C4H18MG0K         8          5
    ## 25:  C4P5NMR0D         6          5
    ## 26:  CD9BZBBDL         3          3
    ## 27:  C191P7JE6         5          5
    ## 28:  C5D6KT798         2          2
    ## 29:  C192JHDND         5          2
    ## 30:  C2E3KFE6P         1          1
    ## 31:  C4RLFGL73         4          2
    ## 32:  CC9564N68         2          2
    ## 33:  CDYTCTC0N         1          1
    ##     channel_id msg_count user_count

``` r
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
all_msgs_2019_df = pd.DataFrame(r.all_msgs_2019)

# Top 10 Users - 90 days
all_msgs_2019_df[all_msgs_2019_df["user_name"] != 'NA']["user_name"].value_counts().nlargest(10).plot.bar()
plt.tight_layout()
plt.show()

# Top 10 Channels - 90 days
```

![](slack_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

``` python
all_msgs_2019_df["channel_name"].value_counts().nlargest(10).plot.bar()
plt.tight_layout()
plt.show()

# Details by channel (message count and unique users count)
```

![](slack_files/figure-gfm/unnamed-chunk-5-2.png)<!-- -->

``` python
channel_details_df = all_msgs_2019_df.groupby(by='channel_name', as_index=False)["user_name"].agg({'msg_count': pd.Series.count, 'user_count': pd.Series.nunique})

channel_details_df.head()
```

    ##            channel_name  msg_count  user_count
    ## 0      36100decepticons         84           1
    ## 1               avacado         22           4
    ## 2          dev_data_vis         38           9
    ## 3          dev_datasets         12           2
    ## 4  dev_machine_learning        138          10

## Data Analysis in R

``` r
channel_details_dt <- py$channel_details_df
setDT(channel_details_dt)

channel_details_dt[order(user_count,msg_count)][1:10]
```

    ##            channel_name msg_count user_count
    ##  1:          free-stuff         1          1
    ##  2:          oth_humour         1          1
    ##  3:    36100decepticons        84          1
    ##  4:  events-of-interest         2          2
    ##  5:          oth_random         2          2
    ##  6: mdsi_cicaround_help         4          2
    ##  7:       ds_hackathons         5          2
    ##  8:        dev_datasets        12          2
    ##  9:     fliparound_chat        31          2
    ## 10:      ds_data_ethics         3          3

``` r
all_msgs_2019[channel_name == '36100decepticons', list(user_id, message_text)][1:10]
```

    ##       user_id          message_text
    ##  1: USLACKBOT Reminder: write data.
    ##  2: USLACKBOT Reminder: write data.
    ##  3: USLACKBOT Reminder: write data.
    ##  4: USLACKBOT Reminder: write data.
    ##  5: USLACKBOT Reminder: write data.
    ##  6: USLACKBOT Reminder: write data.
    ##  7: USLACKBOT Reminder: write data.
    ##  8: USLACKBOT Reminder: write data.
    ##  9: USLACKBOT Reminder: write data.
    ## 10: USLACKBOT Reminder: write data.

``` r
all_msgs_2019[order(-message_reply_count)]
```

    ##       channel_id   user_id
    ##    1:  C18SWDACD U191LC7S4
    ##    2:  CGQREKSBG U4JJKPSNR
    ##    3:  C1924SRPG U18TT99MY
    ##    4:  C1CHS0P45 U191LC7S4
    ##    5:  C1NDAKX39 U4TE2KTPF
    ##   ---                     
    ## 1799:  C1924SRPG U18TT99MY
    ## 1800:  C1924SRPG U9U7AC9QA
    ## 1801:  C18SWDACD U18TT99MY
    ## 1802:  C1924SRPG U18TT99MY
    ## 1803:  C1CHS0P45 U4TE2KTPF
    ##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           message_text
    ##    1:                                                                                                                                                                                                                                                                                                                                                                             Just so all the newbies know. Since you can create custom emojis in slack, you can also 'Andrew ng' a comment and 'Perry' a comment. Over time you will learn where such things are appropriate and how useful they are (very.). :) 
    ##    2:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ##    3:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      testability, being able to treat functions like objects, optimisations, etc
    ##    4: If anyone was considering signing up to tableau for business uses or anything beyond your free student license I would personally recommend not doing so. Have had horrible, delayed, rude and completely ineffective support over the last few weeks. Their solution has simply been 'yeah we can only help if you renew now so pay us 840usd again'. Which isn't a solution... That's just asking to (pay to) be a new customer... \n\nThese days they are just not worth it compared to tools like powerBI which I originally didn't look at but am now quite bullish on.\n\nRant over. Pretty disappointed. 
    ##    5:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              but we can compare a model with human if the outcome is categorical
    ##   ---                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ## 1799:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   yeah there must be some field where it matters
    ## 1800:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         TPI file
    ## 1801:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 Lol I know you have a suit photo I’m sure I’ve seen it somewhere
    ## 1802:                                                                                                                                                                                                                                                                                                                                                                                                                                                    I’ll comment on my thoughts as I go - someone the other day made a comment about teaching people to fish, so I’ll try and keep track of how I track this down
    ## 1803:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             yes, i agreed with alex: vague term so anybody can put a claim to it
    ##       message_timestamp message_attachment_count message_reply_count
    ##    1:        1551954566                        0                  38
    ##    2:        1553081852                        0                  38
    ##    3:        1552806694                        0                  33
    ##    4:        1552880075                        0                  27
    ##    5:        1551930709                        0                  20
    ##   ---                                                               
    ## 1799:        1550800142                        0                   0
    ## 1800:        1551249299                        0                   0
    ## 1801:        1551955578                        0                   0
    ## 1802:        1550799158                        0                   0
    ## 1803:        1552891100                        0                   0
    ##                channel_name channel_is_archived        user_name
    ##    1:    mdsi_announcements                   0     Alex Scriven
    ##    2: mdsi_deeplearn_aut_19                   0             elly
    ##    3:                 dev_r                   0 Perry Stephenson
    ##    4:          dev_data_vis                   0     Alex Scriven
    ##    5:  dev_machine_learning                   0     Jason Nguyen
    ##   ---                                                           
    ## 1799:                 dev_r                   0 Perry Stephenson
    ## 1800:                 dev_r                   0       Justin Mah
    ## 1801:    mdsi_announcements                   0 Perry Stephenson
    ## 1802:                 dev_r                   0 Perry Stephenson
    ## 1803:          dev_data_vis                   0     Jason Nguyen
    ##       user_is_bot message_date       week
    ##    1:           0   2019-03-07 2019-03-04
    ##    2:           0   2019-03-20 2019-03-18
    ##    3:           0   2019-03-17 2019-03-11
    ##    4:           0   2019-03-18 2019-03-18
    ##    5:           0   2019-03-07 2019-03-04
    ##   ---                                    
    ## 1799:           0   2019-02-22 2019-02-18
    ## 1800:           0   2019-02-27 2019-02-25
    ## 1801:           0   2019-03-07 2019-03-04
    ## 1802:           0   2019-02-22 2019-02-18
    ## 1803:           0   2019-03-18 2019-03-18
