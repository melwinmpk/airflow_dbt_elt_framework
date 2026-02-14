# Production-Grade Metadata-Driven ELT Platform

## 1. Project Overview

This project simulates a production-grade modern data platform that ingests data from MySQL, lands it in object storage, performs validation and transformation using dbt, applies advanced data quality checks using both dbt tests and Great Expectations, loads curated datasets into PostgreSQL using SCD and incremental strategies, and finally synchronizes the data into Snowflake for analytics consumption.

The system is fully orchestrated using Apache Airflow with Cosmos integration for dbt execution. The architecture follows industry best practices including layered storage design, metadata-driven configuration, idempotent processing, observability, reprocessing strategy, and CI/CD readiness.

---

## 2. Architecture Overview

### End-to-End Flow

1. MySQL (Source System)
2. Extraction to S3 Raw Zone
3. Bronze Standardization Layer
4. Data Validation (dbt + Great Expectations)
5. PostgreSQL Curated Layer (SCD1, SCD2, Incremental, CDC)
6. Snowflake Analytics Layer

### Storage Zones (Medallion Architecture)

- raw/        → Exact source dumps
- bronze/     → Standardized cleaned parquet files
- silver/     → Business transformations
- gold/       → Analytics-ready datasets

---

## 3. Technology Stack

### Local Development
- Docker Compose
- MySQL container
- PostgreSQL container
- MinIO for S3 simulation
- Apache Airflow
- dbt
- Astronomer Cosmos
- Great Expectations

### Cloud Deployment
- AWS S3
- Snowflake Trial Account

---

## 4. DAG 1: MySQL to S3 Pipeline

### Objective
Extract source data and land it in S3 raw layer in an incremental and idempotent manner.

### Detailed Steps

1. Read table configuration from metadata YAML
2. Identify extraction strategy (full or incremental)
3. Extract using watermark column (updated_at)
4. Convert to Parquet format
5. Partition by ingestion_date
6. Upload to S3 raw zone
7. Log row counts and extraction metrics
8. Update extraction metadata table

### Key Design Decisions
- Watermark-based incremental extraction
- Idempotent file naming with batch_id
- Retry with exponential backoff
- Audit logging table in PostgreSQL
- Deferrable S3 sensor for file validation

---

## 5. DAG 2: S3 to PostgreSQL and Snowflake Pipeline

### Objective
Validate, transform, and load curated data.

### Detailed Steps

1. S3KeySensor (deferrable) waits for raw file
2. Load raw data into bronze layer
3. Run Great Expectations validation suite
4. If validation passes, trigger dbt transformations
5. Run dbt tests and source freshness checks
6. Load into PostgreSQL using:
   - SCD1 merge logic
   - SCD2 snapshot strategy
   - Incremental merge
   - CDC logic handling insert, update, delete
7. Snapshot execution for SCD2 tracking
8. Load curated datasets into Snowflake
9. Update audit logs and execution metrics

Pipeline fails automatically if quality validation fails.

---

## 6. dbt Design Strategy

### Core Components

- Source definitions
- Incremental models with merge strategy
- Snapshots for SCD2
- Custom reusable macros
- Generic tests (not_null, unique)
- Custom business rule tests
- Source freshness checks
- Data contracts enabled
- Exposures for lineage tracking

### Reusable Macro Examples

- Generic SCD2 merge macro
- CDC handling macro
- Dynamic incremental strategy macro

All loads are implemented using dbt models and macros.

---

## 7. Great Expectations Integration

Great Expectations is used as an additional quality gate before dbt transformation begins.

### Purpose

- Schema validation before transformation
- Row count validation against source
- Null threshold enforcement
- Value range checks
- Regex pattern validation
- Duplicate detection

### Integration Approach

1. Create expectation suites per dataset
2. Store suites in version control
3. Run validation checkpoint inside Airflow task
4. If validation fails, stop DAG execution
5. Log validation results to audit table

### Example Validations

- Expect column to not be null
- Expect column values to be unique
- Expect row count to be greater than previous batch
- Expect column to match date format

This introduces an independent validation layer before dbt.

---

## 8. CDC Strategy

Simulated using:

- updated_at timestamp column
- soft delete indicator

Logic handles:
- Insert detection
- Update detection
- Delete detection

Ensures historical tracking in dimension tables.

---

## 9. Metadata-Driven Framework

Instead of hardcoding logic, pipeline is driven by YAML configuration.

Example:

```
tables:
  - name: customers
    load_type: scd2
    primary_key: id
    watermark_column: updated_at
```

Airflow dynamically generates extraction and transformation tasks based on configuration.

---

## 10. Data Quality Framework (Layered)

Quality is implemented in three layers:

Layer 1: Great Expectations (raw validation)
Layer 2: dbt schema and generic tests (transformation layer)
Layer 3: Business rule validations (curated layer)

Quality failures block downstream execution.

---

## 11. Idempotency and Reprocessing

### Idempotency

- Merge-based loading
- No duplicate inserts on rerun
- Partition-based overwrite logic

### Reprocessing Strategy

- Backfill DAG
- Partition reload capability
- Failure isolation per table
- Rollback using transaction control

---

## 12. Observability and Monitoring

- Central audit table
- Row count tracking
- Execution duration metrics
- SLA configuration
- Alert simulation
- Great Expectations validation report logging

---

## 13. Snowflake Design

- External stage configuration
- Incremental merge loading
- Warehouse separation for transform and reporting
- Role-based access simulation
- Clustering key experimentation

---

## 14. CI/CD Readiness

- Dockerized local stack
- Version-controlled expectation suites
- dbt test execution in CI pipeline
- Pre-commit linting
- GitHub Actions simulation

---

## 15. Performance Optimization

- Index strategy in PostgreSQL
- Vacuum and Analyze
- Query plan analysis
- Partition pruning
- Parquet file size tuning

---

## 16. Project Folder Structure

```
project/
 ├── airflow/
 ├── dbt_postgres/
 ├── dbt_snowflake/
 ├── great_expectations/
 ├── docker/
 ├── configs/
 ├── metadata/
 └── logs/
```

---

## 17. Expected Outcomes

- Demonstrates full pipeline ownership
- Shows CDC and SCD mastery
- Proves orchestration expertise
- Integrates dual-layer quality validation
- Reflects production-level engineering design
- Strong portfolio project for senior data engineering interviews

---

## 18. Future Enhancements

- Real MySQL binlog CDC integration
- Data lineage visualization tool integration
- Cost monitoring dashboard
- Streaming ingestion extension
- Lakehouse architecture migration experiment

---

# Final Evaluation

When implemented with metadata-driven orchestration, layered quality validation using both dbt and Great Expectations, idempotent merge logic, observability, and CI/CD integration, this project represents a strong senior-level data engineering portfolio project aligned with modern enterprise standards.

