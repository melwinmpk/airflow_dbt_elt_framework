# airflow_dbt_elt_framework

# ELT Pipeline using Apache Airflow, DBT, MySQL and PostgreSQL

## Project Overview

This project demonstrates an end-to-end ELT (Extract, Load, Transform) pipeline built using **Apache Airflow** and **DBT (Data Build Tool)**. The primary objective was to design a production-style data engineering pipeline while keeping infrastructure costs low by using open source technologies.

The pipeline extracts data from a MySQL database, loads it into PostgreSQL, and performs all business transformations using DBT. Airflow orchestrates the entire workflow, with Cosmos providing seamless integration between Airflow and DBT.

This project was built to gain hands-on experience with modern data engineering practices including orchestration, data modeling, incremental loading, Slowly Changing Dimensions (SCD Type 2), DBT macros, hooks, and reusable transformation logic.

---

# Project Objectives

* Build an end-to-end ELT pipeline
* Integrate Apache Airflow with DBT using Cosmos
* Design Bronze, Silver, and Gold data layers
* Implement SCD Type 2 using DBT
* Build reusable DBT macros
* Configure pre-hooks and post-hooks
* Create incremental and full load strategies
* Apply modular and scalable transformation logic
* Follow data warehouse best practices

---

# Architecture

```
                Kaggle Dataset
                       │
                       ▼
                  MySQL Database
                       │
                (Extract & Load)
                       │
                       ▼
               Apache Airflow DAG
                       │
               Cosmos Integration
                       │
                       ▼
             PostgreSQL Data Warehouse
        ┌──────────┬──────────┬──────────┐
        │          │          │
     Bronze      Silver      Gold
     Layer       Layer       Layer
        │          │          │
        └──────────┴──────────┘
                  DBT
```

---

# Technology Stack

| Component               | Technology                          |
| ----------------------- | ----------------------------------- |
| Workflow Orchestration  | Apache Airflow                      |
| Transformation          | DBT                                 |
| Airflow-DBT Integration | Cosmos                              |
| Source Database         | MySQL                               |
| Data Warehouse          | PostgreSQL                          |
| Programming Language    | Python                              |
| SQL Dialect             | PostgreSQL SQL                      |
| Dataset                 | Kaggle Brazilian E-Commerce Dataset |

---

# Dataset

The project uses the **Brazilian E-Commerce Public Dataset by Olist** available on Kaggle.

The dataset contains multiple related tables including:

* Customers
* Orders
* Order Items
* Payments
* Reviews
* Products
* Sellers
* Geolocation
* Product Category Translation

---

# Data Pipeline

## 1. Extraction

Data is stored in a MySQL database and extracted through Apache Airflow.

## 2. Loading

Airflow loads the raw data into the Bronze schema in PostgreSQL.

## 3. Transformation

DBT transforms Bronze data into Silver and Gold layers.

### Bronze Layer

* Raw source data
* Minimal transformations
* Source-aligned schema

### Silver Layer

* Data cleansing
* Standardization
* Business transformations
* Incremental loading
* SCD Type 2 implementation

### Gold Layer

* Analytics-ready data marts
* Business reporting models
* Aggregated datasets

---

# Key Features Implemented

## Airflow

* DAG-based orchestration
* Task dependencies
* DBT execution using Cosmos
* Modular pipeline design

## DBT

* Models
* Sources
* Seeds (where applicable)
* Incremental models
* Materializations
* Macros
* Pre-hooks
* Post-hooks
* Jinja templating
* Schema management
* Dependency management using `ref()` and `source()`

## SCD Type 2

A reusable SCD Type 2 implementation was developed using DBT.

Features include:

* Historical record preservation
* Record hashing for change detection
* Active/inactive record management
* Effective and expiry timestamps
* Incremental processing

---

# DBT Concepts Explored

During this project, I gained practical experience with:

* DBT project structure
* Model dependencies
* Incremental models
* Materializations
* Macros
* Jinja templating
* Hooks
* Variables
* Config blocks
* Source definitions
* Schema configuration
* Custom SQL logic
* Reusable transformations

---

# Project Structure

```
project/
│
├── dags/
│   ├── airflow_dags
│
├── dbt/
│   ├── models/
│   │   ├── bronze/
│   │   ├── silver/
│   │   └── gold/
│   │
│   ├── macros/
│   ├── tests/
│   ├── snapshots/
│   └── dbt_project.yml
│
├── sql/
├── requirements.txt
└── README.md
```

---

# Learning Outcomes

Through this project I gained hands-on experience in:

* Designing modern ELT pipelines
* Airflow orchestration
* Integrating Airflow and DBT using Cosmos
* Building layered data warehouse architecture
* Writing reusable DBT macros
* Implementing SCD Type 2 in DBT
* Managing incremental data loads
* Using Jinja for dynamic SQL generation
* Developing modular and maintainable transformation logic
* Applying data engineering best practices

---

# Challenges

One planned enhancement was integrating **Great Expectations** for automated data quality validation. Due to time constraints, this integration was not completed and is planned as a future enhancement.

---

# Future Enhancements

* Integrate Great Expectations for data quality validation
* Add DBT documentation generation and hosting
* Implement CI/CD using GitHub Actions
* Containerize the project using Docker
* Add automated testing for Airflow DAGs
* Deploy the pipeline on a cloud platform
* Implement monitoring and alerting

---

# Conclusion

This project demonstrates the development of a complete ELT pipeline using Apache Airflow and DBT while leveraging MySQL and PostgreSQL to create a cost-effective local development environment. It showcases modern data engineering concepts such as orchestration, layered data modeling, incremental processing, reusable DBT macros, hooks, and SCD Type 2 implementation, providing a strong foundation for building scalable and maintainable data pipelines.
