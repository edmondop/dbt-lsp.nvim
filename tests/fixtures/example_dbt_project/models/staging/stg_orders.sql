-- Staging model for orders

{{ config(materialized='view') }}

with source_data as (
    select
        id as order_id,
        customer_id,
        order_date,
        total_amount
    from {{ source('raw', 'orders') }}
)

select * from source_data
