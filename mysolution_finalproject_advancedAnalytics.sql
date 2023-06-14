-- First, I'd loke to show our volume grouth. Can you pull overall session and order volume, trended by quarter for the life business? since the most recent quarter is incomplete, you can decide how to handle it
select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;
/*-------------------------------------------------------------------------------------------------------*/
-- next, lets showcase all of our efficiency improvements. I would love to show quarterly figures since we launched, for session-to-order conversion rate, revenue per order, and revenue per session
select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as session_to_order_conv_rate,
    sum(price_usd)/count(distinct orders.order_id) as revemue_per_order,
    sum(price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;
/*---------------------------------------------------------------------------------------*/
-- I'd like to show how we've grown specific channels. Could you pull a quarterly view of orders from gsearch nonbrand, bsearch nonbrand, brand search overall, organic search, and direct type-in?
select
    year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as gsearch_nonbrand_orders,
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as gsearch_nonbrand_orders,
    count(distinct case when utm_source = 'brand' then orders.order_id else null end) as brand_search_orders,
    count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end) as organic_search_orders,
    count(distinct case when utm_source is null and http_referer is null then orders.order_id else null end) as direct_type_in_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;
/*-------------------------------------------------------------------------------------*/
-- Next, let's show the overall session-to-order conversion rate trends for those same channels, by quarter.
-- please also make a note of any periods where we made major improvments or optimizaztions.
select 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt, 
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
			/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rt,
	COUNT(DISTINCT CASE WHEN utm_source = 'brand' THEN orders.order_id ELSE NULL END) 
			/COUNT(DISTINCT CASE WHEN utm_source = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rt,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv_rt,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_conv_rt
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;
/*--------------------------------------------------------------------------------*/
-- we've come a long way since the days of selling a single product. lets pull monthly trending for revenue and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
select
	year(created_at) as yr,
    month(created_at) as mo,
    sum(case when product_id = 1 then price_usd else null end) as mrfuzzy_rev,
    sum(case when product_id = 1 then price_usd - cogs_usd else null end) as mrfuzzy_marg,
    sum(case when product_id = 2 then price_usd else null end) as lovebear_rev,
    sum(case when product_id = 2 then price_usd - cogs_usd else null end) as lovebear_marg,
    sum(case when product_id = 3 then price_usd else null end) as birthdaybear_rev,
    sum(case when product_id = 3 then price_usd - cogs_usd else null end) as birthdaybear_marg,
    sum(case when product_id = 4 then price_usd else null end) as minibear_rev,
    sum(case when product_id = 4 then price_usd - cogs_usd else null end) as minibear_marg,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
from order_items
group by 1,2
order by 1,2;
/*----------------------------------------------------------------------------------*/
-- lets dive deeper into the impact of introducing new products. please pull monthly sessions to the / products page, and show how % of those sessions clickin through another page has changed over time, along with a view of how conversion from / products to placing an order has improved
create temporary table products_pageviews
select
	website_session_id,
    website_pageview_id,
    created_at as saw_product_page_at
from website_pageviews
where pageview_url = '/products';
-- -- ----
select * from products_pageviews;
-- -- ----
select 
	year(saw_product_page_at) as yr,
	month(saw_product_page_at) as mo,
    count(distinct products_pageviews.website_session_id) as sessions_to_product_page,
    count(distinct website_pageviews.website_session_id) as clicked_to_next_page,
	count(distinct website_pageviews.website_session_id)/count(distinct products_pageviews.website_session_id) as clickthrough_rt,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct products_pageviews.website_session_id) as products_to_order_rt
from products_pageviews
	left join website_pageviews
		on website_pageviews.website_session_id = products_pageviews.website_session_id
		and website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
	left join orders 
		on orders.website_session_id = products_pageviews.website_session_id
group by 1,2;
/*-------------------------------------------------------------------------------*/


    



    
    
    
    
    
    