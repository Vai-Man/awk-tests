library(data.table)
library(ggplot2)
fwrite(x = diamonds, file = "diamonds.csv")

# R-to-AWK Translator

run_awk_query <- function(expr, file = "diamonds.csv", sep = ",") {
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
  
  # Cross-Platform formatting: detect OS to handle shell quoting rules
  os_is_win <- .Platform$OS.type == "windows"
  
  if (os_is_win) {
    # On Windows cmd.exe, the awk script must be enclosed in double quotes.
    # Therefore, any double quotes inside the awk script must be escaped.
    eq_win <- gsub('"', '\\\\"', eq)
    cmd <- sprintf('awk -F "%s" "NR==1 || (%s)" "%s"', sep, eq_win, file)
  } else {
    # On Unix-like systems, single quotes safely enclose the script for bash.
    cmd <- sprintf("awk -F '%s' 'NR==1 || (%s)' '%s'", sep, eq, file)
  }
  
  cat("AWK command:", cmd, "\n")
  
  result <- fread(cmd = cmd, sep = sep)
  print(result)
  
  return(invisible(result))
}

# Demonstrations
r1 <- run_awk_query("price >= 1000", "diamonds.csv")
r2 <- run_awk_query("carat <= 1 and color == 'E'", "diamonds.csv")
r3 <- run_awk_query("cut %in% c('Premium', 'Ideal')", "diamonds.csv")
