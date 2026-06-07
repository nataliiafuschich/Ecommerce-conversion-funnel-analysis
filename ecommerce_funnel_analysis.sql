with session_info as (
select 
user_pseudo_id,
(select value.int_value 
from unnest(event_params)
where key = 'ga_session_id') as session_id,
concat (user_pseudo_id, '.', (select value.int_value 
from unnest(event_params)
where key = 'ga_session_id')) as user_session_id,
REGEXP_EXTRACT((SELECT value.string_value
FROM UNNEST(event_params)
WHERE key = 'page_location'), r'https://[^/]+(/.*)') AS landing_page_location,
traffic_source.source as source,
traffic_source.medium as medium,
traffic_source.name as campaign,
geo. country as country,
geo.city as city,
device.category as device_category,
device.language as device_language,
device.operating_system as os
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'session_start'),
events as (
select 
timestamp_micros(event_timestamp) as event_timestamp,
event_name, 
user_pseudo_id,
(select value.int_value 
from unnest(event_params)
where key = 'ga_session_id') as session_id,
concat (user_pseudo_id, '.', (select value.int_value 
from unnest(event_params)
where key = 'ga_session_id')) as user_session_id
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name in ('session_start', 
'view_item', 
'add_to_cart', 
'begin_checkout', 
'add_shipping_info', 
'add_payment_info', 
'purchase'))
select 
s.user_session_id,
s.landing_page_location, 
s.source,
s.medium,
s.campaign,
s.device_category,
s.device_language,
s.os,
s.country,
s.city,
e.event_timestamp,
e.event_name
from session_info s
left join events e
on s.user_session_id = e.user_session_id


/*Розбивка по юзеру, хороша версія
WITH base AS (
  SELECT
    timestamp_micros(event_timestamp) AS event_timestamp,
    user_pseudo_id,
    event_name,
    (SELECT value.int_value
     FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,
    (SELECT value.string_value
     FROM UNNEST(event_params)
     WHERE key = 'page_location') AS page_location,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    traffic_source.name AS campaign,
    device.category AS device_category,
    device.language AS device_language,
    device.operating_system AS os
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),
landing AS (
  SELECT
  user_pseudo_id,
  session_id,
  REGEXP_EXTRACT(page_location, r'https://[^/]+(/.*)') AS landing_page
  FROM base
  WHERE event_name = 'session_start'
), 
funnel AS (
  SELECT
    user_pseudo_id,
    session_id,
    MAX(event_name = 'session_start') AS session_start,
    MAX(event_name = 'view_item') AS view_item,
    MAX(event_name = 'add_to_cart') AS add_to_cart,
    MAX(event_name = 'begin_checkout') AS begin_checkout,
    MAX(event_name = 'add_shipping_info') AS add_shipping,
    MAX(event_name = 'add_payment_info') AS add_payment,
    MAX(event_name = 'purchase') AS purchase
  FROM base
  GROUP BY user_pseudo_id, session_id
), 
session_info AS (
  SELECT 
  user_pseudo_id,
  session_id,
    ANY_VALUE(source) AS source,
    ANY_VALUE(medium) AS medium,
    ANY_VALUE(campaign) AS campaign,
    ANY_VALUE(device_category) AS device_category,
    ANY_VALUE(device_language) AS device_language,
    ANY_VALUE(os) AS os
  FROM base
  WHERE session_id IS NOT NULL
  GROUP BY user_pseudo_id, session_id
)
SELECT
  CONCAT(s.user_pseudo_id, s.session_id) AS user_session_id,
  s.source,
  s.medium,
  s.campaign,
  s.device_category,
  s.device_language,
  s.os,
  l.landing_page,
  f.session_start,
  f.view_item,
  f.add_to_cart,
  f.begin_checkout,
  f.add_shipping,
  f.add_payment,
  f.purchase
FROM funnel f
LEFT JOIN session_info s
  ON f.user_pseudo_id = s.user_pseudo_id
  AND f.session_id = s.session_id
LEFT JOIN landing l
  ON f.user_pseudo_id = l.user_pseudo_id
  AND f.session_id = l.session_id*/