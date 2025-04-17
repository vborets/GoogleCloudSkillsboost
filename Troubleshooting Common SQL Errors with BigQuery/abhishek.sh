#!/bin/bash

# Color Definitions
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#

# Display header with branding
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}         WELCOME TO DR ABHISHEK CLOUD CHANNEL;              ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${BLUE}${BOLD}          Tutorial by Dr. Abhishek                      ${RESET}"
echo "${YELLOW}For more GCP tutorials, visit: https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"
echo

# Get current project ID
export PROJECT_ID=$(gcloud info --format='value(config.project)')

# Function to run queries with formatting
run_query() {
  local description=$1
  local query=$2
  
  echo "${BLUE}${BOLD}▶ ${description}${RESET}"
  echo "${MAGENTA}Running query...${RESET}"
  bq query --use_legacy_sql=false "$query"
  echo
}

# Visitor Analysis
run_query "1. Basic visitor IDs" \
"
#standardSQL
SELECT fullVisitorId
FROM \`data-to-insights.ecommerce.rev_transactions\`
"

run_query "2. Visitor IDs with page titles" \
"
#standardSQL
SELECT fullVisitorId, hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\` 
LIMIT 1000
"

run_query "3. Page title popularity" \
"
#standardSQL
SELECT
COUNT(DISTINCT fullVisitorId) AS visitor_count,
hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY hits_page_pageTitle
"

run_query "4. Checkout confirmation analysis" \
"
#standardSQL
SELECT
COUNT(DISTINCT fullVisitorId) AS visitor_count,
hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\`
WHERE hits_page_pageTitle = 'Checkout Confirmation'
GROUP BY hits_page_pageTitle
"

# Geographic Analysis
run_query "5. Transactions by city" \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS totals_transactions,
COUNT(DISTINCT fullVisitorId) AS distinct_visitors
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
"

run_query "6. Top cities by visitors" \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS totals_transactions,
COUNT(DISTINCT fullVisitorId) AS distinct_visitors
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
ORDER BY distinct_visitors DESC
"

run_query "7. Average products ordered by city" \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS total_products_ordered,
COUNT(DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT(DISTINCT fullVisitorId) AS avg_products_ordered
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
ORDER BY avg_products_ordered DESC
"

run_query "8. High-value cities (avg > 20 products)" \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS total_products_ordered,
COUNT(DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT(DISTINCT fullVisitorId) AS avg_products_ordered
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
HAVING avg_products_ordered > 20
ORDER BY avg_products_ordered DESC
"

# Product Analysis
run_query "9. Product names and categories" \
"
#standardSQL
SELECT hits_product_v2ProductName, hits_product_v2ProductCategory
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY 1,2
"

run_query "10. Products by category" \
"
#standardSQL
SELECT
COUNT(hits_product_v2ProductName) as number_of_products,
hits_product_v2ProductCategory
FROM \`data-to-insights.ecommerce.rev_transactions\`
WHERE hits_product_v2ProductName IS NOT NULL
GROUP BY hits_product_v2ProductCategory
ORDER BY number_of_products DESC
"

run_query "11. Top 5 product categories" \
"
#standardSQL
SELECT
COUNT(DISTINCT hits_product_v2ProductName) as number_of_products,
hits_product_v2ProductCategory
FROM \`data-to-insights.ecommerce.rev_transactions\`
WHERE hits_product_v2ProductName IS NOT NULL
GROUP BY hits_product_v2ProductCategory
ORDER BY number_of_products DESC
LIMIT 5
"

# Completion message
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}             Lab Completed Successfully!                ${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${RED}${BOLD}🙏 Thank you for following Dr. Abhishek's tutorial!${RESET}"
echo "${YELLOW}${BOLD}📺 Subscribe for more GCP content:${RESET}"
echo "${BLUE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo

#-----------------------------------------------------end----------------------------------------------------------#
