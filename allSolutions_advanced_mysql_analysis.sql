select
	utm_source,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.website_session_id between 1000 and 2000
group by 1;
/*-----------------------------------------------------------------*/
-- We've been live for almost a month now and we're starting to generate sales. can you help me understand where the bulk of our website sessions are comming from, through yesterday?
-- I'd like to see breakdown by UTM source, campaign, and referring domain.
select
	utm_source,
    utm_campaign,
    http_referer,
    count(website_session_id) as sessions
from website_sessions
where created_at < '2012-04-12'
group by 1,2,3
order by 4 desc;
/*--------------------------------------------------------*/
-- Sounds like gsearch nonbrand is our major traffic source, but we need to understand if those sessions are driving sales.
-- Could you calculate the conversion rate (CVR) from session to order? Bases on what we're paying for clicks, we'll need CVR of at least 4% to make the numbers work.
-- If we're much lower, we'll need to reduce bids. if we're higher, we can increase the bids to drive more vloume.
select
	count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as session_to_order_CVR
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-04-14'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';
/*-----------------------------------------------------------------------------------------*/
select
	year(created_at) as created_yr,
    week(created_at) as created_wk,
    count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000
group by 1,2;
/*-----------------------------------------------------------------------------*/
select
	primary_product_id,
    count(distinct case when items_purchased = 1 then order_id else null end) as orders_w_1_item,
    count(distinct case when items_purchased = 2 then order_id else null end) as orders_w_1_item,
    count(distinct order_id) as total_orders
from orders
where order_id between 31000 and 32000
group by 1;
/*------------------------------------------------------------------------------*/
-- based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15.
-- can you pull gsearch nonbrand trended session volume by week, to see if the the bid changes have caused volume to drop at all?
select 
    min(date(created_at)) as week_start_date,
    count(distinct website_sessions.website_session_id) as sessions
from website_sessions

where website_sessions.created_at < '2012-05-10'
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'
group by yearweek(website_sessions.created_at);
/*----------------------------------------------------------------*/
-- i was trying to use our site on my mobile device the other day, and the experience was not great.
-- could you pull conversion rates from session to order, by device type?
-- if desktop performance is better than on mobile we may be able to bid up for desktop specificly to get more volume.
select
	website_sessions.device_type,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id) /count(distinct website_sessions.website_session_id) as conv_rate
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-05-11'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand' 
group by 1;
/*------------------------------------------------------------------------------------*/
-- After your device-level analysis of conversion rates, we realized desktop was doing well, so we bed our gsearch nonbrand desktop campaigns up on 2012-05-19.
-- Could you pull weekly trends for both desktop and mobile so we can see the impact on the volume?
-- you can use  2012-04-15 until the bid change as a baseline.
select
	min(date(created_at)) as week_start_date,
    count(distinct case when device_type = 'desktop' then website_sessions.website_session_id else null end) as dtop_sessions,
    count(distinct case when device_type = 'mobile' then website_sessions.website_session_id else null end) as mob_sessions
from website_sessions
where website_sessions.created_at < '2012-06-09'
	and website_sessions.created_at > '2012-04-15'
    and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'
group by 
	yearweek(website_sessions.created_at);
/*-------------------------------------------------------------------------------*/
select
	pageview_url,
    count(distinct website_pageview_id) as views
from website_pageviews
where website_pageview_id < 1000
group by 1
order by 2 desc;
/*------------------------------------------------------------------------------*/
-- Could you help get my head around the site by pulling the most-viewed website pages, ranked by session volume?
select
	pageview_url,
    count(distinct website_session_id) as sessions
from website_pageviews
where created_at < '2012-06-09'
group by 1
order by 2 desc;
/*---------------------------------------------------------------------------------*/
-- Would you be able to pull a list of the top entry pages? I want to confirm where our users are hitting the site.
-- If you could pull all entry pages and rank them on entry volume, that would be great.
create temporary table first_pageviews_tempTable
select
	website_session_id,
    min(website_pageview_id) as min_pageview_id
from website_pageviews
where created_at < '2012-06-12'
group by 1;

select
	website_pageviews.pageview_url as landing_page,
    count(first_pageviews_tempTable.website_session_id) as sessions_hitting_this_landing_page
from first_pageviews_tempTable
	left join website_pageviews
		on website_pageviews.website_pageview_id = first_pageviews_tempTable.min_pageview_id
group by 1;
/*------------------------------------------------------------------------------------*/
-- After building a new billing page, look and see whether /billing-2 is doing better than the original /billing page?
-- We're wondering what % of sessions on those pages end up placing an order.
select 
	min(website_pageviews.created_at) as first_created_at,
    min(website_pageviews.website_pageview_id) as first_pv_id
from website_pageviews
where pageview_url = '/billing-2';

select 
billing_version_seen,
count(distinct website_session_id) as sessions,
count(distinct order_id) as orders,
count(distinct order_id)/count(distinct website_session_id) as billing_to_order_rt

from(
select 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id
from website_pageviews
	left join orders
		on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.website_pageview_id >= 53550 -- first pageview_id where test was live
	and website_pageviews.created_at < '2012-11-10' -- time of assignment
    and website_pageviews.pageview_url in ('/billing','/billing-2')
    )as billing_sessions_w_orders
    group by 1;
/*-------------------------------------------------------------------------------------------------------------*/
select
	utm_content,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at between '2014-01-01' and '2014-02-01'
group by 1 
order by 2 desc;
/*------------------------------------------------------------------*/
-- With gsearch doing well and the site performing better,  we launched a second paid search channel, bsearch, around August 22.
-- Can you pull weekly trended session volume sine then and cmpare to gsearch nonbrand so i can get a sense for how important this will be for the business?
select
	min(date(created_at)) as week_start_date,
    count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
    count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as gsearch_sessions
from website_sessions
where created_at > '2012-08-22'
	and created_at < '2012-11-29'
    and utm_campaign = 'nonbrand'
group by yearweek(created_at);
/*------------------------------------------------------------------------*/
-- I'd like to learn more about the bsearch nonbrand campaign.
-- Could you please pull the percentage of traffic coming on mobile, and compare that to gsearch?
select
	utm_source,
    count(distinct website_session_id) as sessions,
	count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions ,
    count(distinct case when device_type = 'mobile' then website_session_id else null end)/count(distinct website_session_id) as pct_mobile
from website_sessions
where created_at > '2012-08-22'
	and created_at < '2012-11-30'
    and utm_campaign = 'nonbrand'
group by 1;
/*-------------------------------------------------------------------------------------------*/
-- Could you pull nonbrand conversion rates from session to order for gsearch and bsearch, and slice the data by the device type?
select
	website_sessions.device_type,
    website_sessions.utm_source,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate
from website_sessions
	left join orders
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at > '2012-08-22'
	and website_sessions.created_at < '2012-09-19'
    and website_sessions.utm_campaign = 'nonbrand'
group by 1,2;
/*--------------------------------------------------------------------------------------------------*/
-- pull weekly session volume for gsearch and bserach nonbrand, broken down by device, since Novemper 4th?
-- include a comparison metric to show bsearch a a percent of gsearch for each device.
select
	min(date(created_at)) as week_start_date,
    count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as g_dtop_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end) as b_dtop_sessions,
	count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end)/count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as b_pct_of_g_dtop
    
   ,count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as g_mob_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) as b_mob_sessions,
	count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end)/count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as b_pct_of_g_mob

from website_sessions
where created_at > '2012-11-04'
	and created_at < '2012-12-22'
    and utm_campaign = 'nonbrand'
group by 
	yearweek(created_at);
/*--------------------------------------------------------------------------------------------------*/
select
	case
		when http_referer is null and  is_repeat_session = 0 then 'new_direct_type_in'
        when http_referer is null and  is_repeat_session = 1 then 'repeat_direct_type_in'
        when http_referer in('https://www.gsearch.com','https://www.bsearch.com') and is_repeat_session = 0 then 'new_organic'
        when http_referer in('https://www.gsearch.com','https://www.bsearch.com') and is_repeat_session = 1 then 'repeat_organic'
	else null end as segment,
    count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000 -- for example
	and utm_source is null -- not paid traffic
group by 1;
/*-----------------------------------------------------------------------------------------*/
-- pull organic search, direct type in, and paid brand search sessions by month, and show those sessions as % of paid search nonbrand?
select
	year(created_at) as yr,
    month(created_at) as mo,
    count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as nonbrand,
   
   count(distinct case when channel_group = 'paid_brand' then website_session_id else null end) as brand,
    count(distinct case when channel_group = 'paid_brand' then website_session_id else null end)/count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as brand_pct_of_nonbrand,
    
    count(distinct case when channel_group = 'direct_type_in' then website_session_id else null end) as direct,
    count(distinct case when channel_group = 'direct_type_in' then website_session_id else null end)/count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as direct_pct_of_nonbrand,
    
    count(distinct case when channel_group = 'organic_search' then website_session_id else null end) as direct,
    count(distinct case when channel_group = 'organic_search' then website_session_id else null end)/count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end) as organic_pct_of_nonbrand
    
from(
select
	website_session_id,
    created_at,
    case
		when utm_source is null and http_referer in ('https://www.gsearch.com','https://www.bsearch.com') then 'organic_search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign ='brand' then 'paid_brand'
        when utm_source is null and http_referer is null then 'direct_type_in'
	end as channel_group
from website_sessions
where created_at < '2012-12-23'
) as sessions_w_channel_group_tempTable
group by 1,2;
/*-----------------------------------------------------------------------------------------------------------------------------------------*/
select
	week(created_at) as wk,
	date(created_at) as dt,
	weekday(created_at) as wkday,
	hour(created_at) as hr,
    count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000
group by 1,2,3,4;
/*------------------------------------------------------------------------------------------------------------------------------------------------*/
-- take a look at 2012 monthly and weekly volume patterns
-- pull sessions volume and order volume
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as month,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2013-01-01'
group by 1,2;
/*-------------------------------------------------------------------------------------------------------*/
-- analyze the average website session volume, by hour of day and by day week
select
	hr,
    round(avg(case when wkday = 0 then website_sessions else null end),1) as mon,
    round(avg(case when wkday = 1 then website_sessions else null end),1) as tue,
    round(avg(case when wkday = 2 then website_sessions else null end),1) as wed,
    round(avg(case when wkday = 3 then website_sessions else null end),1) as thu,
    round(avg(case when wkday = 4 then website_sessions else null end),1) as fri,
    round(avg(case when wkday = 5 then website_sessions else null end),1) as sat,
    round(avg(case when wkday = 6 then website_sessions else null end),1) as sun
from
(
select
	date(created_at) as created_date,
    weekday(created_at) as wkday,
    hour(created_at) as hr,
    count(distinct website_session_id) as website_sessions
from website_sessions
where created_at between '2012-09-15'and '2012-11-15'
group by 1,2,3
) daily_hourly_sessions
group by 1;
/*---------------------------------------------------------------------------------*/
select
	primary_product_id,
    count(order_id) as orders,
    sum(price_usd) as revenue,
    sum(price_usd - cogs_usd) as margin,
    avg(price_usd) as average_order_value
from orders
where order_id between 10000 and 11000
group by 1 
order by 4 desc;
/*--------------------------------------------------------------------------------------*/
-- pull monthly trends to date for number of sales, total revenue, and total margin generated for the business?
select
	year(created_at) as yr,
	month(created_at) as mo,
    count(distinct order_id) as number_of_sales,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
from orders
where created_at < '2013-01-04'
group by 1,2;
/*-----------------------------------------------------------------------------------*/
-- send the monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by product, all fro the period since april 1, 2013
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as conv_rate,
    count(distinct case when primary_product_id = 1 then order_id else null end) as product_one_orders,
	count(distinct case when primary_product_id = 2 then order_id else null end) as product_two_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2;
/*----------------------------------------------------------------------------------*/
select
	orders.primary_product_id,
    order_items.product_id as cross_sold_product_id,
    count(distinct orders.order_id) as orders
from orders
	left join order_items
		on orders.order_id = order_items.order_id
        and order_items.is_primary_item = 0
group by 1,2
order by 3 desc;
/*-----------------------------------------------------------------------*/
select 
	order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd as price_paid_usd,
    order_items.created_at,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at
from order_items
	left join order_item_refunds
		on order_item_refunds.order_item_id = order_items.order_item_id
where order_items.order_id in (3489,32049,27061);
/*---------------------------------------------------------------------------*/
select
	year(order_items.created_at) as yr,
	month(order_items.created_at) as mo,
    count(distinct case when product_id = 1 then order_items.order_item_id else null end) as p1_orders,
    count(distinct case when product_id = 1 then order_item_refunds.order_item_id else null end)
		/count(distinct case when product_id = 1 then order_items.order_item_id else null end) as p1_refund_rt,
        
	count(distinct case when product_id = 2 then order_items.order_item_id else null end) as p2_orders,
    count(distinct case when product_id = 2 then order_item_refunds.order_item_id else null end)
		/count(distinct case when product_id = 2 then order_items.order_item_id else null end) as p2_refund_rt,
        
	count(distinct case when product_id = 3 then order_items.order_item_id else null end) as p3_orders,
    count(distinct case when product_id = 3 then order_item_refunds.order_item_id else null end)
		/count(distinct case when product_id = 3 then order_items.order_item_id else null end) as p3_refund_rt,
	
    count(distinct case when product_id = 4 then order_items.order_item_id else null end) as p4_orders,
    count(distinct case when product_id = 4 then order_item_refunds.order_item_id else null end)
		/count(distinct case when product_id = 4 then order_items.order_item_id else null end) as p4_refund_rt
from order_items
	left join order_item_refunds
		on order_items.order_item_id = order_item_refunds.order_item_id
where order_items.created_at < '2014-10-15'
group by 1,2;
/*----------------------------------------------------------------------------------*/
select
	order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd as price_paid_usd,
    order_items.created_at,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at,
    datediff(order_item_refunds.created_at, order_items.created_at) as days_order_to_refund
from order_items
	left join order_item_refunds
		on order_item_refunds.order_item_id = order_items.order_item_id
where order_items.order_id in(3489,32049,27061);
/*------------------------------------------------------------------------------------*/
-- pull a list of compared new vs. repeat sessions by channel
select
	case 
		when utm_source is null and http_referer in ('https://www.gsearch.com','https://www.bsearch.com') then 'organic_search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_source is null and http_referer is null then 'direct_type_in'
        when utm_source = 'socialbook' then 'paid_social'
	end as channel_group,
    count(case when is_repeat_session = 0 then website_session_id else null end) as new_sessions,
    count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_sessions
from website_sessions
where created_at < '2014-11-05'
	and created_at >= '2014-01-01'
group by 1
order by 3 desc;
/*-------------------------------------------------------------------------------*/
-- do a comparison of conversion rates and revenue per session for repeat sessions vs new sessions
select
	is_repeat_session,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    sum(price_usd)/count(distinct website_sessions.website_session_id) as rev_per_session
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2014-11-08'
	and website_sessions.created_at >= '2014-01-01'
group by 1;
    
	
    

    


    
    
    

    

    
    

    


