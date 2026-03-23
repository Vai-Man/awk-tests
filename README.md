## Test Solutions

### 1. Easy Test (`easy_test.R`)
Explains two AWK commands used with `fread()`.
- **Command 1**: `awk -F ',' '{print}' 'diamonds.csv'` - Shows basic file reading.
- **Command 2**: `awk -F ',' '{if(NR > 1) print $1, $2, $7/$1}' 'diamonds.csv'` - Skips the header row, extracts specific columns, calculates price per carat, and handles variable spacing with `fill = T`.

### 2. Medium Test (`medium_test.R`)
Uses AWK logic inside `fread()`.
- **Task 1**: Filters rows where `color == 'E'` and `price > 1500`, prints results, and counts rows.
- **Task 2**: Uses `count++` and `END { print count }` to count rows using AWK without loading data into R.
- **Task 3**: Reads `diamonds.csv` 3 times in one AWK command using combined filters (`carat >= 1`, `cut` in Ideal/Premium, `color` in E/F, `price >= 1000`). Uses `NR==1` to keep the first header, while numeric conditions automatically exclude the subsequent headers.

### 3. Hard Test (`hard_test.R`)
Implements an R to AWK Translator.
- **Public API**: Exposes two dedicated functions (`awk_read()` and `awk_count()`) building on an internal parser (`run_awk_query()`).
  - Dynamically extracts column names from the target dataset and maps them to AWK indices (`$1`, `$2`, etc.) so the function works on any data set.
  - Translates R logic (`and`, `or`, `&`, `|`) into AWK logic (`&&`, `||`).
  - **OS Compatibility**: Detects the host operating system (`.Platform$OS.type`) to correctly format and quote the AWK command strings (handling `cmd.exe` limitations on Windows).
  - **Dependency Verification**: Implements `check_awk_binary()` to safely verify if `awk` or `gawk` is present in the system PATH.
  - **Record Counting**: the native `awk_count()` function prevents data loading entirely and instead compiles an `END {print count}` block within the AWK script, returning an instant, highly memory-efficient integer count of matches directly to R.
- **Execution**: Demonstrates usage of `awk_read()` and `awk_count()` executing translations over `price >= 1000`, `carat <= 1 and color == 'E'`, and `cut %in% c('Premium', 'Ideal')`.

## Requirements
- R >= 4.0.0
- `data.table`
- `ggplot2`
- AWK installed on the system

## How to Run
Source each script to run the tests. Each script creates and deletes `diamonds.csv` independently.
```r
source("easy_test.R")
source("medium_test.R")
source("hard_test.R")
```
