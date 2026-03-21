library(data.table)
library(ggplot2)
setwd("~/Downloads/")
fwrite(x = diamonds, file = "diamonds.csv")

# Task 1: Filter rows where color == 'E' AND price > 1500
t1 <- fread(cmd="awk -F ',' 'NR==1 || ($3==\"E\"&& $7>1500)' diamonds.csv")
print(t1)
cat("Row count:", nrow(t1), "\n")

# Task 2: Count matching rows WITHOUT reading full dataset
t2 <- fread(cmd="awk -F ',' '$3==\"E\"&& $7>1500{count++} END {print count}' diamonds.csv")
cat("Matching rows:", t2[[1]], "\n")

# Task 3: Read diamonds 3x in ONE AWK command with combined filters
# Filters: carat >= 1, cut in (Ideal, Premium), color in (E, F), price >= 1000
t3 <- fread(cmd="awk -F ',' '(NR==1) || ($1>=1 && ($2==\"Ideal\"||$2==\"Premium\") && ($3==\"E\"||$3==\"F\") && $7>=1000)' diamonds.csv diamonds.csv diamonds.csv")
print(t3)
cat("Row count:", nrow(t3), "\n")

