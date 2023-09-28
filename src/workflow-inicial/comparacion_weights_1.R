library(readr)
library(data.table)

BO_log_HT6510_1 <- read_delim("buckets/b1/exp/HT6510_1/BO_log.txt", 
                              delim = "\t", escape_double = FALSE, 
                              trim_ws = TRUE)

BO_log_HT6510_W_0 <- read_delim("buckets/b1/exp/HT6510_W_0/BO_log.txt", 
                                delim = "\t", escape_double = FALSE, 
                                trim_ws = TRUE)

BO_log_HT6510_W_1 <- read_delim("buckets/b1/exp/HT6510_W_1/BO_log.txt", 
                                delim = "\t", escape_double = FALSE, 
                                trim_ws = TRUE)

BO_log_HT6510_1 <- data.table(BO_log_HT6510_1)
BO_log_HT6510_1 <- BO_log_HT6510_1[order(-ganancia)]

BO_log_HT6510_W_0 <- data.table(BO_log_HT6510_W_0)
BO_log_HT6510_W_0 <- BO_log_HT6510_W_0[order(-ganancia)]

BO_log_HT6510_W_1 <- data.table(BO_log_HT6510_W_1)
BO_log_HT6510_W_1 <- BO_log_HT6510_W_1[order(-ganancia)]
