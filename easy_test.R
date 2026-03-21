library(data.table)
library(ggplot2)
setwd("~/Downloads/")
fwrite(x = diamonds[1:5,], file = "diamonds.csv")

# COMMAND 1: awk -F ',' '{print}' 'diamonds.csv'
# Breakdown:
#   -F ','    : Sets the field separator to comma. AWK splits each line into
#               fields ($1, $2, ...) using this delimiter. Essential for CSV.
#   '{print}' : The action block. `print` with no arguments prints the entire
#               current line ($0). This runs for every line (no condition).
#   'diamonds.csv' : The input file AWK reads line-by-line.
#
# What it does:
#   Reads diamonds.csv and prints every line as-is — header included.
#   Equivalent to reading the raw CSV. When wrapped in fread(cmd = ...),
#   fread receives the full CSV text and parses it into a data.table.

fread(cmd = "awk -F ',' '{print}' 'diamonds.csv'")

# COMMAND 2: awk -F ',' '{if(NR > 1) print $1, $2, $7/$1}' 'diamonds.csv'
#
# Breakdown:
#   -F ','       : Same comma delimiter as before.
#   NR           : Built-in AWK variable — "Number of Records". Tracks the
#                  current line number (1-based). NR == 1 is the header row.
#   NR > 1       : Condition that skips the header. Only data rows (2, 3, ...)
#                  pass this check.
#   $1           : First field  → "carat" column.
#   $2           : Second field → "cut" column.
#   $7           : Seventh field → "price" column.
#   $7 / $1      : Computes price-per-carat ratio on the fly.
#   print $1, $2, $7/$1 : Prints carat, cut, and price/carat separated by
#                  spaces (AWK's default output separator).
#
# What it does:
#   Skips the header, then for each data row extracts carat ($1), cut ($2),
#   and computes price/carat ($7/$1). The result is a 3-column space-separated
#   output. fread() with fill=T handles the variable spacing gracefully.
#
# Why fill = T:
#   The output has no header and uses space separation. `fill = T` tells
#   fread to tolerate rows that might have varying field counts (e.g., cut
#   values like "Very Good" would split into two fields).

fread(cmd = "awk -F ',' '{if(NR > 1) print $1, $2, $7/$1}' 'diamonds.csv'", fill = T)