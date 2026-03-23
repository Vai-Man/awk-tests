library(data.table)
library(ggplot2)
fwrite(x = diamonds, file = "diamonds.csv")

# Helper function to detect AWK installation
check_awk_binary <- function() {
  if (Sys.which("awk") != "") {
    return("awk")
  } else if (Sys.which("gawk") != "") {
    return("gawk")
  } else {
    stop("Dependency Error: Neither 'awk' nor 'gawk' is installed or found in the system PATH. Please install AWK to use this package.", call. = FALSE)
  }
}

# R-to-AWK Translator

run_awk_query <- function(expr, file = "diamonds.csv", sep = ",", count_only = FALSE) {
  # Dynamically fetch the available AWK binary
  awk_bin <- check_awk_binary()
  
  # Change single quotes to double quotes for AWK
  eq <- gsub("'", "\"", expr)
  
  # Convert R logical operators to AWK operators
  eq <- gsub("\\band\\b", "&&", eq, ignore.case = TRUE)
  eq <- gsub("\\bor\\b", "||", eq, ignore.case = TRUE)
  
  # Convert %in% statements into multiple OR conditions
  while (grepl("%in%", eq)) {
    # Extract the column name and the list of values inside c(...)
    match_data <- regmatches(eq, regexec("(\\w+)\\s*%in%\\s*c\\(([^)]+)\\)", eq))[[1]]
    col_name <- match_data[2]
    
    # Split the values by comma and clean up spaces
    values <- strsplit(match_data[3], ",")[[1]]
    values <- trimws(values)
    
    # Create the repeated OR clauses, e.g., 'cut == "Premium" || cut == "Ideal"'
    or_clause <- paste(col_name, "==", values, collapse = " || ")
    or_clause_wrapped <- sprintf("(%s)", or_clause)
    
    # Replace the %in% block with our expanded OR sequence
    eq <- sub("(\\w+)\\s*%in%\\s*c\\(([^)]+)\\)", or_clause_wrapped, eq)
  }

  # Read column names from the file header dynamically
  header <- names(fread(file, nrows = 0, sep = sep))
  
  # Map dynamically found columns to AWK fields ($1, $2, ...)
  for (i in seq_along(header)) {
    col_name <- header[i]
    awk_var <- paste("$", i, sep = "")
    # Use word boundaries so that shorter variables don't replace parts of longer ones
    eq <- gsub(sprintf("\\b%s\\b", col_name), awk_var, eq)
  }
  
  # Construct the core awk logic based on whether we are counting or extracting
  if (count_only) {
    # Skip header (NR>1), match the condition, increment a counter, and print at the END
    # count+0 ensures it prints 0 instead of an empty string if no matches are found
    awk_logic <- sprintf("NR>1 && (%s) {count++} END {print count+0}", eq)
  } else {
    # Preserve header row (NR==1) or match the condition to print rows
    awk_logic <- sprintf("NR==1 || (%s)", eq)
  }
  
  # Cross-Platform formatting: detect OS to handle shell quoting rules
  os_is_win <- .Platform$OS.type == "windows"
  
  if (os_is_win) {
    # On Windows cmd.exe, the awk script must be enclosed in double quotes.
    # Therefore, any double quotes inside the awk script must be escaped.
    logic_win <- gsub('"', '\\\\"', awk_logic)
    cmd <- sprintf('%s -F "%s" "%s" "%s"', awk_bin, sep, logic_win, file)
  } else {
    # On Unix-like systems, single quotes safely enclose the script for bash.
    cmd <- sprintf("%s -F '%s' '%s' '%s'", awk_bin, sep, awk_logic, file)
  }
  
  cat("AWK command:", cmd, "\n")
  
  if (count_only) {
    result <- as.integer(fread(cmd = cmd, header = FALSE)[[1]])
    cat("Total Matching Records:", result, "\n")
  } else {
    result <- fread(cmd = cmd, sep = sep)
    print(result)
  }
  
  return(invisible(result))
}

awk_read <- function(expr, file = "diamonds.csv", sep = ",") {
  run_awk_query(expr, file, sep, count_only = FALSE)
}

awk_count <- function(expr, file = "diamonds.csv", sep = ",") {
  run_awk_query(expr, file, sep, count_only = TRUE)
}

# Demonstrations
r1 <- awk_read("price >= 1000", "diamonds.csv")
r2 <- awk_read("carat <= 1 and color == 'E'", "diamonds.csv")
r3 <- awk_read("cut %in% c('Premium', 'Ideal')", "diamonds.csv")

# Record Counting Demonstration
c1 <- awk_count("carat <= 1 and color == 'E'", "diamonds.csv")
