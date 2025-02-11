# Assignment

## Overview
Your task is to create a backend using **TypeScript** and a **PostgreSQL** database. The backend must expose an API that allows for inserting and listing data from a `log` table.

## Requirements
### Database
The PostgreSQL database must contain a single table named `log` with the following columns:
- **id**: Primary key
- **inserted_at**: `timestamptz` with a default value of `now()`
- **json**: `json` type

All columns must be defined with the `NOT NULL` constraint.

### Backend API
The backend should expose an API that allows:
1. **Insertion** of new log entries
2. **Listing** existing log entries

### CI/CD Pipeline
- Implement a **CI/CD pipeline** using **GitHub Actions**.
- The pipeline should include:
  - Automated tests
  - Deployment using **Infrastructure as Code (IaC)**
  - Support for deployment in any environment

## Time Estimate
This assignment is expected to take approximately **1-3 hours**.

## Tools & Environment
Feel free to use any tools, frameworks, or environments that you are comfortable with to complete this task.

## Submission
Ensure your code is well-documented and structured. Provide instructions on how to set up and run the project in a `README.md` file.


# INFRASTRUCTURE 

