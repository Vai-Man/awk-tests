library(data.table)
library(ggplot2)
fwrite(x = diamonds, file = "diamonds.csv")

# R-to-AWK Translator

run_awk_query <- function(expr, file = "diamonds.csv") {
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

  # Map known diamonds columns to AWK indices
  col_dict <- c("carat" = "$1", "cut" = "$2", "color" = "$3", "clarity" = "$4", 
                "depth" = "$5", "table" = "$6", "price" = "$7", 
                "x" = "$8", "y" = "$9", "z" = "$10")
  
  for (col in names(col_dict)) {
    eq <- gsub(col, col_dict[[col]], eq)
  }
  
  # Build and run the command
  cmd <- sprintf("awk -F ',' 'NR==1 || (%s)' '%s'", eq, file)
  cat("AWK command:", cmd, "\n")
  print(fread(cmd = cmd))
}

# Demonstrations
r1 <- run_awk_query("price >= 1000", "diamonds.csv")
r2 <- run_awk_query("carat <= 1 and color == 'E'", "diamonds.csv")
r3 <- run_awk_query("cut %in% c('Premium', 'Ideal')", "diamonds.csv")
