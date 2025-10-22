-- Staging model for customers
-- This is used for integration testing

{{ config(materialized='view') }}

with source_data as (
    select
        id as customer_id,
        name as customer_name,
        email as customer_email,
        created_at
    from {{ source('raw', 'customers') }}
)

select * from source_data
