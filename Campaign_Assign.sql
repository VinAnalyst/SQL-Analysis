/* Author: Vinit R
Created:2020/10/05 
Desciption: Campaign_Assignment
Database: GCP Big Query
*/

-- 1) In the CampaignMembers table, there should only be one unique LeadID / CampaignID combination. 
--    As a QA check, write a SQL statement that returns any LeadID / CampaignID combination that occurs more than once in the table.

Query : SELECT		CONCAT(CampaignID,LeadID) AS Campaign_LeadID, # Add Campaign_Id and lead_ID as one unique_id
  				    COUNT(CampaignMemberID) AS Members_Count
	    FROM	   `data-analysis-2020.Data_Analysis.CampaignMembers` 
	    GROUP BY	CONCAT(CampaignID, LeadID)
	    HAVING  	COUNT (CampaignMemberID) > 1;  # For Sanity or QA check to identify/remove duplicates

-- 2) If our business logic dictates that in cases of duplication, we only want to keep the first LeadID / CampaignID combination based on the 
--    CampaignMemberSignUpDate, write a SQL statement that returns the entire CampaignMembers table, but only keeps the first LeadID / CampaignID 
--    combination. Be mindful of potential “ties” in the CampaignMemberSignUpDate.

Query: SELECT   CONCAT( CampaignID,LeadID ) AS CampaignIDLeadID,
                MIN(CampaignMemberSignupDate) AS CampaignMemberSignUpDate # Here we are using Min to get the first sign_up date of members
       FROM    `data-analysis-2020.Data_Analysis.Campaign_Members`
       GROUP BY CONCAT( CampaignID, LeadID );


-- 3) Write a SQL statement that returns all Campaign Names that have no ‘Attended’ campaign members, excluding Campaigns that have yet to start.
-- The result should be only a list of Campaign IDs.

Query: SELECT   A.CampaignID,
		        A.CampaignName
	   FROM   `data-analysis-2020.Data_Analysis.Campaigns` A
	   JOIN   `data-analysis-2020.Data_Analysis.Campaign_Members` B
	   ON      (A.CampaignID = B.CampaignID)
	   WHERE    B.CampaignMemberStatus <> 'Attended'; 


-- 4) Write a SQL statement that returns each campaign type and the three lead names that have the most attendance for each campaign type.

Query: SELECT A.CampaignType,
       A.LeadName
	   FROM ( SELECT A.CampaignType,
              C.LeadName,
              ROW_NUMBER() OVER (PARTITION BY A.CampaignType ORDER BY C.LeadName ASC) AS SUCCESS # We are using windows function to get campaign type
       FROM  `data-analysis-2020.Data_Analysis.Campaigns` A
       JOIN `data-analysis-2020.Data_Analysis.CampaignMembers` B
       ON     (A.CampaignID = B.CampaignID)
       JOIN   `data-analysis-2020.Data_Analysis.Leads` C
       ON    (B.LeadID = C.LeadID) ) A
       WHERE   A.SUCCESS <= 3;
