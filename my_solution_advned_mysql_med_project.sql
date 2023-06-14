-- Gserach seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders so that can showcase the growth there?
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
	and website_sessions.utm_source = 'gsearch'
group by 1,2;
/*------------------------------------------------------------------------------------*/
-- It woulld be great  to see a similar monthly trend for gsearch, but this time splitting out nonbrand and brand campaigns separatly. im wondering if brand picking up at all, if so, this is a good story to tell
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct case when utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions,
	count(distinct case when utm_campaign = 'nonbrand' then orders.order_id else null end) as nonbrand_orders,
    count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_sessions,
	count(distinct case when utm_campaign = 'brand' then orders.order_id else null end) as brand_orders
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
	and website_sessions.utm_source = 'gsearch'
group by 1,2;
/*----------------------------------------------------------------*/
-- could you dive into nonbrnad, and pull monthly sessions and orders split by device type? i want to flex our analytical mucsels a little and show the board we really know our traffic sources
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct case when device_type = 'desktop' then website_sessions.website_session_id else null end) as desktop_sessions,
    count(distinct case when device_type = 'desktop' then orders.order_id else null end) as desktop_orders,
    count(distinct case when device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_sessions,
    count(distinct case when device_type = 'mobile' then orders.order_id else null end) as desktop_orders
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'
group by 1,2;
/*-------------------------------------------------------------------*/
-- I'm worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. can you pull monthly trneds for gsearch, alongside monthly trends for each our other channels?
select distinct	
	utm_source,
    utm_campaign,
    http_referer
from website_sessions
where website_sessions.created_at < '2012-11-27';

select
	year(website_sessions.created_at) as yr,
	month(website_sessions.created_at) as mo,
    count(distinct case when utm_source = 'gsearch' then website_sessions.website_session_id else null end) as gsearch_paid_sessions,
    count(distinct case when utm_source = 'bsaerch' then website_sessions.website_session_id else null end) as bsearch_paid_sessions,
    count(distinct case when utm_source is null  and http_referer is not null then website_sessions.website_session_id else null end) as organic_paid_sessions,
    count(distinct case when utm_source is null  and http_referer is not null then website_sessions.website_session_id else null end) as direct_type_in_sessions
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1,2;
/*---------------------------------------------------------------*/
-- I'd like to tell the story pf our website performance improvments over the course of the first 8 months, could you pull session to order conversion rates, by month?
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
	count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1,2;
/*-------------------------------------------------------------------------------*/
-- for the gsearch lander test, please estimate the revenue that test earned us
-- (Hint: Look at the increase in CVR from the test (Jun 19 - Jul 28), and use nonbrand sessions and revenue since to calculate incremental value)
select
	min(website_pageview_id) as first_test_pv
from website_pageviews
where pageview_url = '/lander-1';
-- -- ----
create temporary table temp_table_FTPv
select 
	website_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	inner join website_sessions
		on website_sessions.website_session_id = website_pageviews.website_session_id
        and website_sessions.created_at < '2012-07-28'
        and website_pageviews.website_pageview_id >= 23504
        and utm_source = 'gsearch'
        and utm_campaign = 'nonbrand'
group by 1;
-- -- ----
create temporary table nonbrand_test_sessions_w_landing_pages
select 
	temp_table_FTPv.website_session_id,
    website_pageviews.pageview_url as landing_page
from temp_table_FTPv
	left join website_pageviews
		on website_pageviews.website_pageview_id = temp_table_FTPv.min_pageview_id
where website_pageviews.pageview_url in('/home','/lander-1');

select * 
from nonbrand_test_sessions_w_landing_pages;
-- -- ----
create temporary table nonbrand_test_sessions_w_orders
select
	nonbrand_test_sessions_w_landing_pages.website_session_id,
    nonbrand_test_sessions_w_landing_pages.landing_page,
    orders.order_id as order_id
from nonbrand_test_sessions_w_landing_pages
	left join orders
		on orders.website_session_id = nonbrand_test_sessions_w_landing_pages.website_session_id;
-- -- ----
select
	landing_page,
    count(distinct website_session_id) as session,
    count(distinct order_id) as orders,
    count(distinct order_id) / count(distinct website_session_id)
from nonbrand_test_sessions_w_orders
group by 1;
-- -- ----
select
	max(website_sessions.website_session_id) as most_recent_gsearch_nonbrand_home_pageview
from website_sessions
left join website_pageviews
	on website_pageviews.website_session_id = website_sessions.website_session_id
where utm_source = 'gsearch'
	and utm_campaign = 'nonbrand'
    and pageview_url = '/home'
    and website_sessions.created_at < '2012-11-27';
-- -- ----
select
	count(website_session_id) as sessions_since_test
from website_sessions
where created_at < '2012-11-27'
	and website_session_id > 17145
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';
    -- at the end i didnt understand the previous example ***********************
/*-------------------------------------------------------------*/
-- for the landing page test you analyzed previously, it would be great to show a full funnel from of the two pages to orders.  you can use the same time period you analyzyed last time.
select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    -- website_pageviews.created_at,
	case when pageview_url = '/home' then 1 else 0 end as homepage,
	case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
	case when pageview_url = '/products' then 1 else 0 end as products_page,
	case when pageview_url = '/the-original_mr_fuzzy' then 1 else 0 end as mrfuzzy_page,
	case when pageview_url = '/cart' then 1 else 0 end as cart_page,
	case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
	case when pageview_url = '/billing' then 1 else 0 end as billing_page,
	case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
	and website_sessions.created_at < '2012-07-28'
    and website_sessions.created_at > '2012-06-19'
order by
	website_sessions.website_session_id,
    website_pageviews.created_at;
-- -- ----
CREATE TEMPORARY TABLE session_level_made_it_flagged
select
	website_session_id,
    max(homepage) as saw_homepage,
    max(custom_lander) as saw_custom_lander,
    max(products_page) as product_made_it,
    max(mrfuzzy_page) as mrfuzzy_made_it,
    max(cart_page) cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
	max(thankyou_page) as thankyou_made_it
from (
select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    -- website_pageviews.created_at,
	case when pageview_url = '/home' then 1 else 0 end as homepage,
	case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
	case when pageview_url = '/products' then 1 else 0 end as products_page,
	case when pageview_url = '/the-original_mr_fuzzy' then 1 else 0 end as mrfuzzy_page,
	case when pageview_url = '/cart' then 1 else 0 end as cart_page,
	case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
	case when pageview_url = '/billing' then 1 else 0 end as billing_page,
	case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
	and website_sessions.created_at < '2012-07-28'
    and website_sessions.created_at > '2012-06-19'
order by
	website_sessions.website_session_id,
    website_pageviews.created_at
) as pageview_level
group by 1;
-- -- ----
select 
	case 
		when saw_homepage = 1 then 'saw_homepage'
		when saw_custom_lander = 1 then 'saw_custom_lander'
        else 'uh oh... check logic'
	end as segment,
    count(distinct website_session_id) as sessions,
    count(distinct case when product_made_it = 1 then website_session_id else null end) as to_products,
    count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_mrfuzzy,
    count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_shipping,
    count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billing,
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thankyou
from session_level_made_it_flagged
group by 1;
-- -- ---- 
SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
	END AS segment, 
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_click_rt,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_level_made_it_flagged
GROUP BY 1;
/*-------------------------------------------------------------------------------------------------------------------------------------------------*/
-- I'd love for you to quantify the impact of our billing test, as well. please analyze the lift generated from the test, in terms of revenue per billing page session, and then pull the number of billing page sessions for the past month to understand montly impact.
SELECT 
	billing_version_seen,
	count(distinct website_session_id) as sessions,
    sum(price_usd)/count(distinct website_session_id) as revenue_per_billing_page_seen
from(
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at > '2012-09-10'
	and website_pageviews.created_at < '2012-11-10'
    and website_pageviews.pageview_url in ('/billing','/billing-2')
    ) as billing_pageviews_and_order_data
group by 1;
-- -- ----
select
	count(website_session_id) as billing_sessions_past_month
from website_pageviews
where website_pageviews.pageview_url in('/billing','/billing-2')
	and created_at between '2012-10-17' and '2012-11-27';


        
    
    

        










    

    
	



    
    
    
    
    
    

    
    