/***  TRANSACTIONS ***/
/***  TRANSACTIONS ***/

WITH vars AS (
  SELECT 
    DATEADD(MONTH, -1, DATE_TRUNC('MONTH', CURRENT_DATE())) AS start_date,
    CURRENT_DATE() AS end_date
)

select  
       TO_DATE(HstAKOrder.DATEOFBUSINESS) as DATEOFBUSINESS,
       HstAKOrder.FKSTOREID,
       SUBSTR(DIM_STORE.MMX_STORENAME, 1,9) as MMX_NUMSTORE,
      
       DIM_PERIODPLANNING.PERIODE_PLANNING,
       DIM_PERIODPLANNING.MOIS, 
       DIM_PERIODPLANNING.CATEGORY,
       DIM_PERIODPLANNING.JOUR,
       
       
       (Case When  OrderMode.Name like '%B>%' then 'Kiosk'
               else 'Drive' 
               end) as "Canal", 
               
        (Case when (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 1200 and 1259) 
            then '12H-13H'
            else (Case when (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 1300 and 1359) 
                       then '13H-14H'
                        else (Case when (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 1900 and 1959) 
                               then '19H-20H'
                        else (Case when  (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 2000 and 2059) 
                               then '20H-21H'
                        else 'autre'    
                            end)
                     
                        end)

                     end)
            end )  as "Horaires Rush" 
            ,
            APPROX_COUNT_DISTINCT (UniqueID) as "Nb Transaction"
      
      
FROM 

KFC_FRANCE_DL_DEV.NCR.HSTAKORDER  
	inner join  KFC_FRANCE_DL_DEV.NCR.OrderMode on OrderMode.OrderModeId = HstAKOrder.FKOrderModeID
    inner join  KFC_FRANCE_DW_DEV.DWH.DIM_STORE on DIM_STORE.ID_STORE = HstAKOrder.FKSTOREID
    left  join  KFC_FRANCE_DW_DEV.DWH.DIM_PERIODPLANNING on HstAKOrder.DATEOFBUSINESS =DIM_PERIODPLANNING.BUSINESSDATE  
    CROSS JOIN vars


    
 WHERE
        HstAKOrder.DATEOFBUSINESS BETWEEN vars.start_date AND vars.end_date
        AND (OrderMode.Name like '%B>%' OR OrderMode.Name like '%Drive%')
        AND DIM_STORE.MMX_STORENAME NOT LIKE '%CLOSED%' 
        AND DIM_STORE.MMX_STORENAME <> ''
        AND lasttimebumped < 3000 
        AND lasttimebumped > 15


group by 
       HstAKOrder.DATEOFBUSINESS, 
       HstAKOrder.FKSTOREID,
  SUBSTR(DIM_STORE.MMX_STORENAME, 1,9),

       DIM_PERIODPLANNING.PERIODE_PLANNING,
       DIM_PERIODPLANNING.MOIS, 
       DIM_PERIODPLANNING.CATEGORY,
       DIM_PERIODPLANNING.JOUR,
       
   (Case When  OrderMode.Name like '%B>%' then 'Kiosk'
               else 'Drive' 
               end), 
               
     (Case when (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 1200 and 1259) 
            then '12H-13H'
            else (Case when (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 1300 and 1359) 
                       then '13H-14H'
                        else (Case when (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 1900 and 1959) 
                               then '19H-20H'
                        else (Case when  (((hour(HSTAKORDER.TIMESTARTED)*100) + minute(HSTAKORDER.TIMESTARTED)*1) between 2000 and 2059) 
                               then '20H-21H'
                        else 'autre'    
                            end)
                     
                        end)

                     end)
            end ) 

having "Horaires Rush" not like 'autre'   AND HstAKOrder.DATEOFBUSINESS <  DATEADD(DAY, -MOD(DAYOFWEEK(CURRENT_DATE()) + 4, 7), CURRENT_DATE())